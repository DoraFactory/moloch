
//Remix Version of v0.3 of smart contract
pragma solidity ^0.5.3;

//use compiler +0.5.3 in remix
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/GSN/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/Roles.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/roles/WhitelistAdminRole.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
/*
    This contract requires the above OpenZeppelin imports. 

    OPEN TODO's: 
    - ADD multi-sig for admins
        https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol?
    
    -switch from "Signers" to "Whitelist" from Openzeppelin - signers is just for ease of developemenmt: DONE
  
    - make functions "Pauseable"??? 
   
    - allow for proxing of only a percentage of votes in 'updateDelegateKey' - would need to update submitVote as well. 
    
    -upon removal of a member, The LAO currently lets that member get their fairshare back of non-deployed funds, but..
    ...do we allow them to take out any perceived gains in equity? Or, just make the member leave any of those potential gains on the table. 
    ...maybe solution is to make them saleable/transferrable to other LAO members?  : LEAVE GAINS ON TABLE 
    
    -Break the Venture Moloch Contract into smaller components/contracts
    
    - "deposit" requires pre-approved tokens in order to transfer. 
    
    - consider making totalAvalilable, based on guildBank.balance instead of totalContributed

    -payable functions 

working on possiblity of making 'shares' standard erc-20s
*/



contract GuildBank is Ownable {
    using SafeMath for uint256;
   
    IERC20 private contributionToken; // contribution token contract reference

    event Withdrawal(address indexed receiver, uint256 amount);
    //event FundsWithdrawal(address indexed applicant, uint256 fundsRequested);
    event AssetWithdrawal(IERC20 assetToken, address indexed receiver, uint256 amount);
 
    // contributionToken is used to fund ventures and distribute dividends, e.g., wETH or DAI
    constructor(address contributionTokenAddress) public {
        contributionToken = IERC20(contributionTokenAddress);
    }

    // withdraw contribution tokens 
    function withdraw(address receiver, uint256 amount) public onlyOwner returns (bool) {
        emit Withdrawal(receiver, amount);
        return contributionToken.transfer(receiver, amount);
    }
      
    // onlySummoner in Moloch can withdraw equity tokens
    function adminWithdrawAsset(IERC20 assetToken, address receiver, uint256 amount) public onlyOwner returns(bool) {
        emit AssetWithdrawal(assetToken, receiver, amount);
        return IERC20(assetToken).transfer(receiver, amount);
    }   
    
}


contract VentureMoloch is Ownable,WhitelistAdminRole, WhitelistedRole {
    using SafeMath for uint256;

    /***************
    GLOBAL CONSTANTS
    ***************/
    uint256 public periodDuration; // default = 17280 = 4.8 hours in seconds (5 periods per day)
    uint256 public votingPeriodLength; // default = 35 periods (7 days)
    uint256 public gracePeriodLength; // default = 35 periods (7 days)
    uint256 public abortWindow; // default = 5 periods (1 day)
    uint256 public dilutionBound; // default = 3 - maximum multiplier a YES voter will be obligated to pay in case of mass ragequit
    uint256 public summoningTime; // needed to determine the current period
    //address private summoner; // Moloch summoner address reference for certain admin controls;
    
    IERC20 public contributionToken; // contribution token contract reference
    IERC20 private tributeToken; // tribute token contract reference 
    GuildBank public guildBank; // guild bank contract reference
    uint256 private decimalFactor = 10**uint256(18); // wei conversion reference
    // HARD-CODED LIMITS
    // These numbers are quite arbitrary; they are small enough to avoid overflows when doing calculations
    // with periods or shares, yet big enough to not limit reasonable use cases.
    uint256 constant MAX_VOTING_PERIOD_LENGTH = 10**18; // maximum length of voting period
    uint256 constant MAX_GRACE_PERIOD_LENGTH = 10**18; // maximum length of grace period
    uint256 constant MAX_DILUTION_BOUND = 10**18; // maximum dilution bound
    uint256 constant MAX_NUMBER_OF_SHARES = 10**18; // maximum number of shares that can be minted

    /***************
    EVENTS
    ***************/
    event SubmitProposal(
        uint256 proposalIndex, 
        address indexed delegateKey, 
        address indexed memberAddress, 
        address indexed applicant, 
        uint256 tributeAmount, 
        IERC20 tributeToken, 
       // uint256 sharesRequested, //remove so only proposals. 
        uint256 fundsRequested,
        string details);
    event SubmitVote(
        uint256 indexed proposalIndex, 
        address indexed delegateKey, 
        address indexed memberAddress, 
        uint8 uintVote);
    event ProcessProposal(
            uint256 indexed proposalIndex,
            address indexed memberAddress, 
            address indexed applicant, 
            uint256 tributeAmount,
            IERC20 tributeToken,
            //uint256 sharesRequested, //0
            uint256 fundsRequested,
            string details,
            bool didPass);
    event Ragequit(address indexed memberAddress);
    event Abort(uint256 indexed proposalIndex, address applicantAddress);
    event UpdateDelegateKey(address indexed memberAddress, address newDelegateKey);
    //event SummonComplete(address indexed summoner, uint256 shares);
    event MemberAdded(address indexed _newMemberAddress, uint256 _sharesRequested, uint256 _tributeAmount);
   event  DividendDeclared(uint256 indexed amountPerShare);
   event DividendWithdrawn(address indexed memberAddress, uint256 indexed amount);
   event ProposalFunded(uint256 proposalIndex, address applicant, uint256 amountFunded);
   event Deposit(address indexed depositor, uint256 indexed amount);

    /******************
    INTERNAL ACCOUNTING
    ******************/
    uint256 public totalShares = 0; // total shares across all members
    uint256 public totalSharesRequested = 0; // total shares that have been requested in unprocessed proposals 
    // guild bank accounting in base contribution token
    uint256 public totalContributed = 0; // total member contributions to guild bank
    uint256 public totalWithdrawals = 0; // total member and funding withdrawals from guild bank
    uint256 public totalValuePerShare = 0; //total of all member's tributeAmounts/totalShares 
   
    enum Vote {
        Null, // default value, counted as abstention
        Yes,
        No
    }
    
    /*
        @dev Add-on terms from original Moloch Code: 
         uint256 tributeAmount,
    */
    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of shares assigned to this member
        bool exists; // always true once a member has been created
        uint256 tributeAmount; // amount contributed by member to guild bank (determines fair share)
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES    
        uint256 allowedDividends; //authorized amount to withdraw
        uint256 valuePerShare;  //based on the tributeAmount given when buying 100,000 shares. 
    }
    
    /*
        @dev Add-on terms from original Moloch Code: 
        -IERC20 tributeToken,
        -uint256 fundsRequested
        TODO: remove sharesREquested? 
    */
    struct Proposal {
        address proposer; // the member who submitted the proposal
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals
        uint256 tributeAmount; // amount of tokens offered as tribute
        IERC20 tributeToken; // the tribute token reference for subscription or alternative contribution
       // uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 fundsRequested; // the funds requested for applicant 
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool processed; // true only if the proposal has been processed
        bool didPass; // true only if the proposal passed
        bool fundsTransferred;
        bool aborted; // true only if applicant calls "abort" before end of voting period
        uint256 maxTotalSharesAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
        mapping (address => Vote) votesByMember; // the votes on this proposal by each member
    }
    /****
    MAPPINGS
    *****/

    mapping (address => Member) public members;
    mapping (address => address) public memberAddressByDelegateKey;
    Proposal[] public ProposalQueue;
    address[] public memberAccts; 
    IERC20 [] public equityHoldingsAddress;
     //mapping (IERC20 => uint) public equityHoldings;
    
    /********
    MODIFIERS
    ********/ 
 
    
    modifier onlyMember {
        require(members[msg.sender].shares > 0, "Moloch::onlyMember - not a member");
        _;
    }

    modifier onlyDelegate {
        require(members[memberAddressByDelegateKey[msg.sender]].shares > 0, "Moloch::onlyDelegate - not a delegate");
        _;
    }

    /********
    FUNCTIONS
    ********/
    constructor(
        //address _summoner,
        address _contributionToken,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _abortWindow,
        uint256 _dilutionBound
    ) public {
        //require(_summoner != address(0), "Moloch::constructor - summoner cannot be 0");
        require(_contributionToken != address(0), "Moloch::constructor - _contributionToken cannot be 0");
        require(_periodDuration > 0, "Moloch::constructor - _periodDuration cannot be 0");
        require(_votingPeriodLength > 0, "Moloch::constructor - _votingPeriodLength cannot be 0");
        require(_votingPeriodLength <= MAX_VOTING_PERIOD_LENGTH, "Moloch::constructor - _votingPeriodLength exceeds limit");
        require(_gracePeriodLength <= MAX_GRACE_PERIOD_LENGTH, "Moloch::constructor - _gracePeriodLength exceeds limit");
        require(_abortWindow > 0, "Moloch::constructor - _abortWindow cannot be 0");
        require(_abortWindow <= _votingPeriodLength, "Moloch::constructor - _abortWindow must be smaller than or equal to _votingPeriodLength");
        require(_dilutionBound > 0, "Moloch::constructor - _dilutionBound cannot be 0");
        require(_dilutionBound <= MAX_DILUTION_BOUND, "Moloch::constructor - _dilutionBound exceeds limit");
        
        // contribution token is the base token for guild bank accounting
        contributionToken = IERC20(_contributionToken);

        guildBank = new GuildBank(_contributionToken);

        periodDuration = _periodDuration;
        votingPeriodLength = _votingPeriodLength;
        gracePeriodLength = _gracePeriodLength;
        abortWindow = _abortWindow;
        dilutionBound = _dilutionBound;

        summoningTime = now;
    }

    /*****************
    PROPOSAL FUNCTIONS
    *****************/
    function submitProposal(
        address applicant,
        uint256 tributeAmount,
        IERC20 _tributeToken,
        //uint256 sharesRequested,
        uint256 fundsRequested,
        string memory details
    )
        public
        onlyDelegate
    {
        require(applicant != address(0), "Moloch::submitProposal - applicant cannot be 0");

        // Make sure we won't run into overflows when doing calculations with shares.
        // Note that totalShares + totalSharesRequested + sharesRequested is an upper bound
        // on the number of shares that can exist until this proposal has been processed.
        // require(totalShares.add(totalSharesRequested).add(sharesRequested) <= MAX_NUMBER_OF_SHARES, "Moloch::submitProposal - too many shares requested");
        
        // totalSharesRequested = totalSharesRequested.add(sharesRequested);

        address memberAddress = memberAddressByDelegateKey[msg.sender];
        
        tributeToken = IERC20(_tributeToken);
        
        // collect token tribute from applicant and store it in the Moloch until the proposal is processed
        require(tributeToken.transferFrom(applicant, address(this), tributeAmount), "Moloch::submitProposal - tribute token transfer failed");
        
        // compute startingPeriod for proposal
        uint256 startingPeriod = max(
            getCurrentPeriod(),
            ProposalQueue.length == 0 ? 0 : ProposalQueue[ProposalQueue.length.sub(1)].startingPeriod
        ).add(1);

        // create proposal ...
        Proposal memory proposal = Proposal({
            proposer: memberAddress,
            applicant: applicant,
            tributeAmount: tributeAmount,
            tributeToken: tributeToken,
            //sharesRequested: sharesRequested,
            //sharesRequested: 0,
            fundsRequested: fundsRequested,
            details: details,
            startingPeriod: startingPeriod,
            yesVotes: 0,
            noVotes: 0,
            processed: false,
            didPass: false,
           fundsTransferred: false,
            aborted: false,
            maxTotalSharesAtYesVote: 0
        });

        // ... and append it to the queue
        ProposalQueue.push(proposal);

        uint256 proposalIndex = ProposalQueue.length.sub(1);
        emit SubmitProposal(
            proposalIndex, 
            msg.sender, 
            memberAddress, 
            applicant, 
            tributeAmount,
            tributeToken,
            //sharesRequested,
            fundsRequested,
            details);
    }
    
    function submitVoteOnProposal(uint256 proposalIndex, uint8 uintVote) public onlyDelegate {
        address memberAddress = memberAddressByDelegateKey[msg.sender];
        Member storage member = members[memberAddress];

        require(proposalIndex < ProposalQueue.length, "Moloch::submitVote - proposal does not exist");
        Proposal storage proposal = ProposalQueue[proposalIndex];

        require(uintVote < 3, "Moloch::submitVote - uintVote must be less than 3");
        Vote vote = Vote(uintVote);

        require(getCurrentPeriod() >= proposal.startingPeriod, "Moloch::submitVote - voting period has not started");
        require(!hasVotingPeriodExpired(proposal.startingPeriod), "Moloch::submitVote - proposal voting period has expired");
        require(proposal.votesByMember[memberAddress] == Vote.Null, "Moloch::submitVote - member has already voted on this proposal");
        require(vote == Vote.Yes || vote == Vote.No, "Moloch::submitVote - vote must be either Yes or No");
        require(!proposal.aborted, "Moloch::submitVote - proposal has been aborted");

        // store vote
        proposal.votesByMember[memberAddress] = vote;

        // count vote
        if (vote == Vote.Yes) {
            proposal.yesVotes = proposal.yesVotes.add(member.shares);

            // set highest index (latest) yes vote - must be processed for member to ragequit
            if (proposalIndex > member.highestIndexYesVote) {
                member.highestIndexYesVote = proposalIndex;
            }

            // set maximum of total shares encountered at a yes vote - used to bound dilution for yes voters
            if (totalShares > proposal.maxTotalSharesAtYesVote) {
                proposal.maxTotalSharesAtYesVote = totalShares;
            }

        } else if (vote == Vote.No) {
            proposal.noVotes = proposal.noVotes.add(member.shares);
        }

        emit SubmitVote(proposalIndex, msg.sender, memberAddress, uintVote);
    }

    function processProposal(uint256 proposalIndex) public {
        require(proposalIndex < ProposalQueue.length, "Moloch::processProposal - proposal does not exist");
        Proposal storage proposal = ProposalQueue[proposalIndex];

        require(getCurrentPeriod() >= proposal.startingPeriod.add(votingPeriodLength).add(gracePeriodLength),"Moloch::processProposal - proposal is not ready to be processed");
        require(proposal.processed == false, "Moloch::processProposal - proposal has already been processed");
        require(proposalIndex == 0 || ProposalQueue[proposalIndex.sub(1)].processed, "Moloch::processProposal - previous proposal must be processed");

        proposal.processed = true;
        //totalSharesRequested = totalSharesRequested.sub(proposal.sharesRequested);
        
        bool didPass = proposal.yesVotes > proposal.noVotes;

        // Make the proposal fail if the dilutionBound is exceeded
        if (totalShares.mul(dilutionBound) < proposal.maxTotalSharesAtYesVote) {
            didPass = false;
        }

        // PROPOSAL PASSED
        if (didPass && !proposal.aborted) {

            proposal.didPass = true;
        } 


        else {
            // return all tribute tokens to the applicant
            require(
                proposal.tributeToken.transfer(proposal.applicant, proposal.tributeAmount),
                "Moloch::processProposal - failing vote token transfer failed"
            );
        }

        emit ProcessProposal(
            proposalIndex,
            proposal.proposer,
            proposal.applicant,
            proposal.tributeAmount,
            proposal.tributeToken,
            //proposal.sharesRequested,
            proposal.fundsRequested,
            proposal.details,
            didPass
        );
    }
    
    /*
        @dev fund a project that has passed and been processed. 
        This function is needed in case an Applicant does not have their legal
        documents in order, but has passed for funding.
        This avoids having to delay processing proposals. 
    */
    function fundApprovedProposal(uint index) public onlyWhitelisted
     {
        Proposal storage proposal = ProposalQueue[index];
        //proposal must have passed
        require ( proposal.didPass == true); 
        //proposal must not have been already funded.  to proposal struc "fundsTransfered"
        require (proposal.fundsTransferred == false); 

        // update total guild bank withdrawal tally to reflect requested funds disbursement 
        totalWithdrawals = totalWithdrawals.add(proposal.fundsRequested);
        //mapping equity address to amount of tokens 
       // equityHoldings[proposal.tributeToken] = proposal.tributeAmount;
       // push IERC 20 address into array. 
        equityHoldingsAddress.push(proposal.tributeToken) -1;

        //fund the project
        require(
                guildBank.withdraw(proposal.applicant, proposal.fundsRequested),
                "Moloch::fundApprovedProposal - withdrawal of funding tokens from guildBank failed"
            );
        
        //transfer the equity to guild bank
            require(
                proposal.tributeToken.transfer(address(guildBank), proposal.tributeAmount),
                "Moloch::fundApprovedProposal - equity token transfer to guild bank failed"
            );

       proposal.fundsTransferred = true; 
       emit ProposalFunded(index, proposal.applicant, proposal.fundsRequested);
       //emit Proposal Funded - index no, proposal.applicant, fundsTransferred, 
    } 
     
    function rageQuit() public onlyMember {
        Member storage member = members[msg.sender];

        require(canRageQuit(member.highestIndexYesVote), "Moloch::ragequit - cant ragequit until highest index proposal member voted YES on is processed");

         //calc fair share - combine these into own function?
        //All Member contributions - All Member withdrawals
        uint256 totalAvailable = getTotalAvailable();     
         //WITH HELPER FUNCTION 
        uint256 economicWeight = getMemberEconomicWeight(msg.sender);
        //GET % OF MEMBER'S from totalAvalailbe using decimalFactor as multiplier 
        uint256 withdrawalAmount = economicWeight.mul(totalAvailable).div(decimalFactor);

         //withdraw based on member's shares to total shares
        // uint256 withdrawalAmount = member.shares.mul(valuePerShare);
        uint256 valuePerShare = member.valuePerShare;
       
        // burn shares and other pertinent membership records
        totalShares = totalShares.sub(member.shares);
        member.shares = 0;
        member.tributeAmount = 0; 
        member.exists = false; 
        member.valuePerShare = 0; 
        //update public tallys 
        totalWithdrawals = totalWithdrawals.add(withdrawalAmount); // update total guild bank withdrawal tally to reflect raqequit amount
        totalValuePerShare = totalValuePerShare.sub(valuePerShare);  //update tally for totalValuePerShare
      //remove member from the memberAccts array
        memberAccts.pop();    
        // instruct guild bank to transfer withdrawal amount to ragequitter
        require(
            guildBank.withdraw(msg.sender, withdrawalAmount),
            "Moloch::ragequit - withdrawal of tokens from guildBank failed"
        );

        emit Ragequit(msg.sender);
    }
    
    /*
        An applicant can cancel their proposal within Moloch voting grace period.
        Any tribute amount put up for membership and/or guild bank funding will then be returned.
    */
    function abortProposal(uint256 proposalIndex) public {
        require(proposalIndex < ProposalQueue.length, "Moloch::abort - proposal does not exist");
        Proposal storage proposal = ProposalQueue[proposalIndex];

        require(msg.sender == proposal.applicant, "Moloch::abort - msg.sender must be applicant");
        require(getCurrentPeriod() < proposal.startingPeriod.add(abortWindow), "Moloch::abort - abort window must not have passed");
        require(!proposal.aborted, "Moloch::abort - proposal must not have already been aborted");

        uint256 tokensToAbort = proposal.tributeAmount;
        proposal.tributeAmount = 0;
        proposal.aborted = true;

        // return all tribute tokens to the applicant
        require(
            proposal.tributeToken.transfer(proposal.applicant, tokensToAbort),
            "Moloch::abort- failed to return tribute to applicant"
        );

        emit Abort(proposalIndex, msg.sender);
    }


    //enable a proxy for voting rights of member
    function updateDelegateKey(address newDelegateKey) public onlyMember {
        require(newDelegateKey != address(0), "Moloch::updateDelegateKey - newDelegateKey cannot be 0");

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != msg.sender) {
            require(!members[newDelegateKey].exists, "Moloch::updateDelegateKey - cant overwrite existing members");
            require(!members[memberAddressByDelegateKey[newDelegateKey]].exists, "Moloch::updateDelegateKey - cant overwrite existing delegate keys");
        }

        Member storage member = members[msg.sender];
        memberAddressByDelegateKey[member.delegateKey] = address(0);
        memberAddressByDelegateKey[newDelegateKey] = msg.sender;
        member.delegateKey = newDelegateKey;

        emit UpdateDelegateKey(msg.sender, newDelegateKey);
    }

    // Extension to original Moloch Code: Summoner withdraws and administers tribute tokens (but not member contributions or dividends)
    function adminWithdrawAsset(IERC20 assetToken, address receiver, uint256 amount) onlyWhitelisted public returns (bool)  {
        require(assetToken != contributionToken); 
        return guildBank.adminWithdrawAsset(assetToken, receiver, amount);
    }

    //@dev function to add a member without going through submit proposal process
    function  addMember (address _newMemberAddress, uint256 _tributeAmount) onlyWhitelisted public returns(bool) {       
           require(members[_newMemberAddress].exists  == false, "Moloch::member already exists");
           require(_newMemberAddress != address(0), "Moloch::addMember - applicant cannot be 0");
            //require new member address to not exist    

            //TEST calculate valuePerShare over 100,000 shares
            uint valuePerShare = _tributeAmount.div(100000);  
           //add shares to Member struct
           members[_newMemberAddress] = Member(_newMemberAddress, 100000, true, _tributeAmount, 0, 0, valuePerShare);
           //add member address to delegate key
           memberAddressByDelegateKey[_newMemberAddress] = _newMemberAddress;
           //update contributions to GuildBank 
           totalContributed = totalContributed.add(_tributeAmount);
           //add shares to Total Shares
           totalShares = totalShares.add(100000);
           //add a member's valuePerShare - to overall total value per share
          totalValuePerShare = totalValuePerShare.add(valuePerShare);
            // transfer contribution token to guild bank
            require(contributionToken.transferFrom(_newMemberAddress, address(guildBank), _tributeAmount), "Moloch::submitProposal - tribute token transfer failed");
            //add address to member accounts arrary
            memberAccts.push(_newMemberAddress) -1;
            //emit event 
            emit MemberAdded(_newMemberAddress, 100000, _tributeAmount);
    }

   
       //helper to calculate economic wieght - uses 'decimalFactor' to manage overflows
    /*
        Example of how getMemberEconomicWeight works: 
        1.if a new member contributed 100,000 DAI for 1000,000 shares, member.valuePerShare = 1; 
        2. and there was a total of 1,000,000 shares purchased in total for 1,000,000 DAI between all members, then
        economicWeight of the new member = 1/10 = .1 (multiplied by decimalFactor to handle wei math);
    */
    function getMemberEconomicWeight (address currentMember) internal view returns (uint256){
        Member storage member = members[currentMember];
        uint256 X =  (member.valuePerShare.mul(decimalFactor)).div(totalValuePerShare);
            return X; 
    }
    
    // @dev forces a current member out
    function  removeMember (address currentMember) onlyWhitelisted public returns(bool)  {
        Member storage member = members[currentMember];
       
        //? change to .exits == true ?
       // require(members[currentMember].exists == true, "Moloch - address is not a member");
        require(members[currentMember].shares > 0, "Moloch::removeMember - no shares to burn");
        
         //calc fair share 

        //All Member contributions - All Member withdrawals
        uint256 totalAvailable = getTotalAvailable();       
        //WITH HELPER FUNCTION 
        uint256 economicWeight = getMemberEconomicWeight(currentMember);
        //GET % OF MEMBER'S from totalAvalailbe using decimalFactor as multiplier 
        uint256 withdrawalAmount = economicWeight.mul(totalAvailable).div(decimalFactor);

        uint256 valuePerShare = member.valuePerShare;
        // burn shares and other pertinent membership records
        totalShares = totalShares.sub(member.shares);
        member.shares = 0;
        member.tributeAmount = 0; 
        member.exists = false; 
        member.valuePerShare = 0; 
        //update public tallys 
        totalWithdrawals = totalWithdrawals.add(withdrawalAmount); // update total guild bank withdrawal tally to reflect raqequit amount
      
       totalValuePerShare = totalValuePerShare.sub(valuePerShare);  //update tally for totalValuePerShare
      //remove member from the memberAccts array
        memberAccts.pop();     
        // instruct guild bank to transfer withdrawal amount to member
        require(
            guildBank.withdraw(currentMember, withdrawalAmount),
            "Moloch::ragequit - withdrawal of tokens from guildBank failed"
        );

        emit Ragequit(currentMember);
    }

    /*
        @param amountPerShare in Wei format 
       ( amountPerShare ) x (valuePerShare[member address]) x (# of shares[member address]) =
        amount authorized to a single member ..

       * Number of members = total amount authorized as dividend overall

    */
    function declareDividend (uint256 amountPerShare)  onlyWhitelisted public  {
   
         uint256 totalAvailable = getTotalAvailable();
        //total of all dividends can not exceed total contributions - withdrawals
        //Add multiple of totalValuePerShare = totalContributed/totalShares 
       // uint shareMultiple = totalContributed.div(totalShares); 
        require(totalAvailable > amountPerShare.mul(totalShares).mul(totalValuePerShare), "Moloch:declareDividend - Not enough funds available");

        //iterate over the length memberAccts array and add to members[i].allowedDividends 
        for(uint256 i = 0; i < memberAccts.length; i++)
        {
                address memberAddress = memberAccts[i];
                uint256 valuePerShare = members[memberAddress].valuePerShare;
                //pull this value from the Member Struct
                 uint256 allowedDividends = members[memberAddress].shares.mul(amountPerShare).mul(valuePerShare);
                 //add to a member's allowed dividends 
                members[memberAddress].allowedDividends = members[memberAddress].allowedDividends.add(allowedDividends);                      
        }
        emit DividendDeclared(amountPerShare);
    }
    

    //@dev - allow member to withdraw all authorized dividends. 
    function withdrawAuthorizedDividend () public onlyMember {
       
       uint256 memberDividend = members[msg.sender].allowedDividends;
       
        require ( memberDividend > 0, "Moloch: withdrawAuthorizedDividend - no dividends available for withdrawal" );
        
        totalWithdrawals = totalWithdrawals.add(memberDividend);
        
         members[msg.sender].allowedDividends = 0; 

        require (guildBank.withdraw(msg.sender, memberDividend));  

        emit DividendWithdrawn(msg.sender, memberDividend);
        // return true;
    }
   

    /*
        @dev deposit for contribution token --e.g. from sale of a company
         - only adds to 'totalContributed', so it wont be used in any fair share calculations. 
         - need to pre approve VM contract address. -- fix
         @param amount = amount in Wei format of the Contribution Token 
    */
    function deposit (uint256 amount) public returns(bool) {
        //add to totalContributed
        totalContributed = totalContributed.add(amount);
        require(contributionToken.transferFrom(msg.sender,address (guildBank), amount));
        emit Deposit (msg.sender, amount);

        //TEST this -- may not need pre-approval??
        //require (IERC20.transfer(address(guildBank), amount));
        
    }
    
    /***************
    GETTER FUNCTIONS
    ***************/
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function getCurrentPeriod() public view returns (uint256) {
        return now.sub(summoningTime).div(periodDuration);
    }

    //return list of all member addressess. 
    function  getMember () view public returns ( address [] memory) {
        return memberAccts;
    }
    //details for any member address
    function  getMemberDetails (address _member) public view returns(address, uint, bool, uint, uint) {     
         return (members[_member].delegateKey, members[_member].shares, members[_member].exists, members[_member].tributeAmount, members[_member].highestIndexYesVote);
    }
    //some details for proposal
    function getProposalDetails(uint256  index ) public view returns(address proposer,address applicant, uint256 fundsRequested, uint tributeAmount, IERC20 tributeAddress, bool passed){
        require(index < ProposalQueue.length, "Moloch::getProposalDetails - proposal doesn't exist");
        return (ProposalQueue[index].proposer,ProposalQueue[index].applicant, ProposalQueue[index].fundsRequested,ProposalQueue[index].tributeAmount,
        ProposalQueue[index].tributeToken, ProposalQueue[index].didPass);
    }
  

    function getProposalQueueLength() public view returns (uint256) {
        return ProposalQueue.length;
    }
    
    // can only ragequit if the latest proposal you voted YES on has been processed
    function canRageQuit(uint256 highestIndexYesVote) public view returns (bool) {
        require(highestIndexYesVote < ProposalQueue.length, "Moloch::canRageQuit - proposal does not exist");
        return ProposalQueue[highestIndexYesVote].processed;
    }

    function hasVotingPeriodExpired(uint256 startingPeriod) public view returns (bool) {
        return getCurrentPeriod() >= startingPeriod.add(votingPeriodLength);
    }

    function getProposalVote(address memberAddress, uint256 proposalIndex) public view returns (Vote) {
        require(members[memberAddress].exists, "Moloch::getProposalVote - member doesn't exist");
        require(proposalIndex < ProposalQueue.length, "Moloch::getProposalVote - proposal doesn't exist");
        return ProposalQueue[proposalIndex].votesByMember[memberAddress];
    }
    //get GuildBank balance for an equity token
    function getEquityBalance(IERC20 assetToken)  view public returns (uint256) {
        return IERC20(assetToken).balanceOf(address(guildBank));
    }
    function getEquityTokenAddresses () view public returns(IERC20 [] memory)  {
        return equityHoldingsAddress;
    }

    function getTotalAvailable () view public returns (uint256){
        return totalContributed.sub(totalWithdrawals);
    }
    ///at what period does the voting period end. 
     function whenProposalVotingPeriodEnd (uint256 proposalIndex)  public view returns (uint){
       uint startingPeriod = ProposalQueue[proposalIndex].startingPeriod;
       return startingPeriod.add(votingPeriodLength);
    }        
} //end of K 

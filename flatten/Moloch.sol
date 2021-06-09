// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/oz/Ownable.sol

pragma solidity >0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/GuildBank.sol

pragma solidity >0.6.0;

contract GuildBank is Ownable {
    using SafeMath for uint256;

    IERC20 public approvedToken; // approved token contract reference

    event Withdrawal(address indexed receiver, uint256 amount);

    constructor(address approvedTokenAddress) public {
        approvedToken = IERC20(approvedTokenAddress);
    }

    function withdraw(
        address receiver,
        uint256 shares,
        uint256 totalShares
    ) public onlyOwner returns (bool) {
        uint256 amount =
            approvedToken.balanceOf(address(this)).mul(shares).div(totalShares);
        emit Withdrawal(receiver, amount);
        return approvedToken.transfer(receiver, amount);
    }

    function transfer(address receiver, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        emit Withdrawal(receiver, amount);
        return approvedToken.transfer(receiver, amount);
    }
}

// File: contracts/Moloch.sol

pragma solidity >0.6.0;

contract Moloch is Ownable {
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

    IERC20 public approvedToken; // approved token contract reference; default = wETH
    GuildBank public guildBank; // guild bank contract reference

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
        address indexed applicant,
        uint256 tokenTribute,
        uint256 sharesRequested
    );
    event SubmitVote(
        uint256 indexed proposalIndex,
        address indexed delegateKey,
        address indexed memberAddress,
        uint8 uintVote
    );
    event ProcessProposal(
        uint256 indexed proposalIndex,
        address indexed applicant,
        uint256 tokenTribute,
        uint256 sharesRequested,
        bool didPass
    );
    event Ragequit(address indexed memberAddress, uint256 sharesToBurn);
    event Abort(uint256 indexed proposalIndex, address applicantAddress);
    event UpdateDelegateKey(
        address indexed memberAddress,
        address newDelegateKey
    );
    event SummonComplete(address indexed summoner, uint256 shares);

    /******************
    INTERNAL ACCOUNTING
    ******************/
    uint256 public totalShares = 0; // total shares across all members
    uint256 public totalSharesRequested = 0; // total shares that have been requested in unprocessed proposals

    enum Vote {
        Null, // default value, counted as abstention
        Yes,
        No
    }

    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of shares assigned to this member
        bool exists; // always true once a member has been created
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
    }

    struct Proposal {
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals
        uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool processed; // true only if the proposal has been processed
        bool didPass; // true only if the proposal passed
        bool aborted; // true only if applicant calls "abort" fn before end of voting period
        uint256 tokenTribute; // amount of tokens offered as tribute
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 maxTotalSharesAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
        mapping(address => Vote) votesByMember; // the votes on this proposal by each member
    }

    mapping(address => bool) public whitelist;
    mapping(address => Member) public members;
    mapping(address => address) public memberAddressByDelegateKey;
    Proposal[] public proposalQueue;

    /********
    MODIFIERS
    ********/
    modifier onlyWhitelist {
        require(
            whitelist[msg.sender],
            "Moloch::onlyWhitelist - not in the whitelist"
        );
        _;
    }

    modifier onlyMember {
        require(
            members[msg.sender].shares > 0,
            "Moloch::onlyMember - not a member"
        );
        _;
    }

    modifier onlyDelegate {
        require(
            members[memberAddressByDelegateKey[msg.sender]].shares > 0,
            "Moloch::onlyDelegate - not a delegate"
        );
        _;
    }

    /********
    FUNCTIONS
    ********/
    constructor(
        address summoner,
        address _approvedToken,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _abortWindow,
        uint256 _dilutionBound
    ) public {
        require(
            summoner != address(0),
            "Moloch::constructor - summoner cannot be 0"
        );
        require(
            _approvedToken != address(0),
            "Moloch::constructor - _approvedToken cannot be 0"
        );
        require(
            _periodDuration > 0,
            "Moloch::constructor - _periodDuration cannot be 0"
        );
        require(
            _votingPeriodLength > 0,
            "Moloch::constructor - _votingPeriodLength cannot be 0"
        );
        require(
            _votingPeriodLength <= MAX_VOTING_PERIOD_LENGTH,
            "Moloch::constructor - _votingPeriodLength exceeds limit"
        );
        require(
            _gracePeriodLength <= MAX_GRACE_PERIOD_LENGTH,
            "Moloch::constructor - _gracePeriodLength exceeds limit"
        );
        require(
            _abortWindow > 0,
            "Moloch::constructor - _abortWindow cannot be 0"
        );
        require(
            _abortWindow <= _votingPeriodLength,
            "Moloch::constructor - _abortWindow must be smaller than or equal to _votingPeriodLength"
        );
        require(
            _dilutionBound > 0,
            "Moloch::constructor - _dilutionBound cannot be 0"
        );
        require(
            _dilutionBound <= MAX_DILUTION_BOUND,
            "Moloch::constructor - _dilutionBound exceeds limit"
        );

        approvedToken = IERC20(_approvedToken);

        guildBank = new GuildBank(_approvedToken);

        periodDuration = _periodDuration;
        votingPeriodLength = _votingPeriodLength;
        gracePeriodLength = _gracePeriodLength;
        abortWindow = _abortWindow;
        dilutionBound = _dilutionBound;

        summoningTime = now;

        members[summoner] = Member(summoner, 1, true, 0);
        memberAddressByDelegateKey[summoner] = summoner;
        totalShares = 1;

        emit SummonComplete(summoner, 1);
    }

    /*****************
    PROPOSAL FUNCTIONS
    *****************/

    function addWhitelist(address applicant) public onlyDelegate {
        whitelist[applicant] = true;
    }

    function removeWhitelist(address applicant) public onlyDelegate {
        whitelist[applicant] = false;
    }

    function submitProposal(
        uint256 tokenTribute,
        uint256 sharesRequested,
        string memory details
    ) public onlyWhitelist {
        require(
            msg.sender != address(0),
            "Moloch::submitProposal - applicant cannot be 0"
        );

        // Make sure we won't run into overflows when doing calculations with shares.
        // Note that totalShares + totalSharesRequested + sharesRequested is an upper bound
        // on the number of shares that can exist until this proposal has been processed.
        require(
            totalShares.add(totalSharesRequested).add(sharesRequested) <=
                MAX_NUMBER_OF_SHARES,
            "Moloch::submitProposal - too many shares requested"
        );

        totalSharesRequested = totalSharesRequested.add(sharesRequested);

        // collect tribute from applicant and store it in the Moloch until the proposal is processed
        require(
            approvedToken.transferFrom(msg.sender, address(this), tokenTribute),
            "Moloch::submitProposal - tribute token transfer failed"
        );

        // compute startingPeriod for proposal
        uint256 startingPeriod = getCurrentPeriod().add(1);

        // create proposal ...
        Proposal memory proposal =
            Proposal({
                applicant: msg.sender,
                sharesRequested: sharesRequested,
                startingPeriod: startingPeriod,
                yesVotes: 0,
                noVotes: 0,
                processed: false,
                didPass: false,
                aborted: false,
                tokenTribute: tokenTribute,
                details: details,
                maxTotalSharesAtYesVote: 0
            });

        // ... and append it to the queue
        proposalQueue.push(proposal);

        uint256 proposalIndex = proposalQueue.length.sub(1);
        emit SubmitProposal(
            proposalIndex,
            msg.sender,
            tokenTribute,
            sharesRequested
        );
    }

    function submitVote(uint256 proposalIndex, uint8 uintVote)
        public
        onlyDelegate
    {
        address memberAddress = memberAddressByDelegateKey[msg.sender];
        Member storage member = members[memberAddress];

        require(
            proposalIndex < proposalQueue.length,
            "Moloch::submitVote - proposal does not exist"
        );
        Proposal storage proposal = proposalQueue[proposalIndex];

        require(
            uintVote < 3,
            "Moloch::submitVote - uintVote must be less than 3"
        );
        Vote vote = Vote(uintVote);

        require(
            getCurrentPeriod() >= proposal.startingPeriod,
            "Moloch::submitVote - voting period has not started"
        );
        require(
            !hasVotingPeriodExpired(proposal.startingPeriod),
            "Moloch::submitVote - proposal voting period has expired"
        );
        require(
            proposal.votesByMember[memberAddress] == Vote.Null,
            "Moloch::submitVote - member has already voted on this proposal"
        );
        require(
            vote == Vote.Yes || vote == Vote.No,
            "Moloch::submitVote - vote must be either Yes or No"
        );
        require(
            !proposal.aborted,
            "Moloch::submitVote - proposal has been aborted"
        );

        // store vote
        proposal.votesByMember[memberAddress] = vote;

        // count vote
        if (vote == Vote.Yes) {
            proposal.yesVotes = proposal.yesVotes.add(member.shares);

            // set highest index (latest) yes vote - must be processed for member to ragequit
            member.highestIndexYesVote = proposalIndex + 1;

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
        require(
            proposalIndex < proposalQueue.length,
            "Moloch::processProposal - proposal does not exist"
        );
        Proposal storage proposal = proposalQueue[proposalIndex];

        require(
            getCurrentPeriod() >=
                proposal.startingPeriod.add(votingPeriodLength).add(
                    gracePeriodLength
                ),
            "Moloch::processProposal - proposal is not ready to be processed"
        );
        require(
            proposal.processed == false,
            "Moloch::processProposal - proposal has already been processed"
        );
        // TODO: This is not necessary
        // require(
        //     proposalIndex == 0 || proposalQueue[proposalIndex.sub(1)].processed,
        //     "Moloch::processProposal - previous proposal must be processed"
        // );

        proposal.processed = true;
        totalSharesRequested = totalSharesRequested.sub(
            proposal.sharesRequested
        );

        bool didPass = proposal.yesVotes > proposal.noVotes;

        // Make the proposal fail if the dilutionBound is exceeded
        if (totalShares.mul(dilutionBound) < proposal.maxTotalSharesAtYesVote) {
            didPass = false;
        }

        // PROPOSAL PASSED
        if (didPass && !proposal.aborted) {
            proposal.didPass = true;

            // if the applicant is already a member, add to their existing shares
            if (members[proposal.applicant].exists) {
                members[proposal.applicant].shares = members[proposal.applicant]
                    .shares
                    .add(proposal.sharesRequested);

                // the applicant is a new member, create a new record for them
            } else {
                // if the applicant address is already taken by a member's delegateKey, reset it to their member address
                if (
                    members[memberAddressByDelegateKey[proposal.applicant]]
                        .exists
                ) {
                    address memberToOverride =
                        memberAddressByDelegateKey[proposal.applicant];
                    memberAddressByDelegateKey[
                        memberToOverride
                    ] = memberToOverride;
                    members[memberToOverride].delegateKey = memberToOverride;
                }

                // use applicant address as delegateKey by default
                members[proposal.applicant] = Member(
                    proposal.applicant,
                    proposal.sharesRequested,
                    true,
                    0
                );
                memberAddressByDelegateKey[proposal.applicant] = proposal
                    .applicant;
            }

            // mint new shares
            totalShares = totalShares.add(proposal.sharesRequested);

            // transfer tokens to guild bank
            require(
                approvedToken.transfer(
                    address(guildBank),
                    proposal.tokenTribute
                ),
                "Moloch::processProposal - token transfer to guild bank failed"
            );

            // PROPOSAL FAILED OR ABORTED
        } else {
            // return all tokens to the applicant
            require(
                approvedToken.transfer(
                    proposal.applicant,
                    proposal.tokenTribute
                ),
                "Moloch::processProposal - failing vote token transfer failed"
            );
        }

        emit ProcessProposal(
            proposalIndex,
            proposal.applicant,
            proposal.tokenTribute,
            proposal.sharesRequested,
            didPass
        );
    }

    function ragequit(uint256 sharesToBurn) public onlyMember {
        uint256 initialTotalShares = totalShares;

        Member storage member = members[msg.sender];

        require(
            member.shares >= sharesToBurn,
            "Moloch::ragequit - insufficient shares"
        );

        require(
            canRagequit(member.highestIndexYesVote),
            "Moloch::ragequit - cant ragequit until highest index proposal member voted YES on is processed"
        );

        // burn shares
        member.shares = member.shares.sub(sharesToBurn);
        totalShares = totalShares.sub(sharesToBurn);

        // instruct guildBank to transfer fair share of tokens to the ragequitter
        require(
            guildBank.withdraw(msg.sender, sharesToBurn, initialTotalShares),
            "Moloch::ragequit - withdrawal of tokens from guildBank failed"
        );

        emit Ragequit(msg.sender, sharesToBurn);
    }

    function abort(uint256 proposalIndex) public {
        require(
            proposalIndex < proposalQueue.length,
            "Moloch::abort - proposal does not exist"
        );
        Proposal storage proposal = proposalQueue[proposalIndex];

        require(
            msg.sender == proposal.applicant,
            "Moloch::abort - msg.sender must be applicant"
        );
        require(
            getCurrentPeriod() < proposal.startingPeriod.add(abortWindow),
            "Moloch::abort - abort window must not have passed"
        );
        require(
            !proposal.aborted,
            "Moloch::abort - proposal must not have already been aborted"
        );

        uint256 tokensToAbort = proposal.tokenTribute;
        proposal.tokenTribute = 0;
        proposal.aborted = true;

        // return all tokens to the applicant
        require(
            approvedToken.transfer(proposal.applicant, tokensToAbort),
            "Moloch::processProposal - failed to return tribute to applicant"
        );

        emit Abort(proposalIndex, msg.sender);
    }

    function updateDelegateKey(address newDelegateKey) public onlyMember {
        require(
            newDelegateKey != address(0),
            "Moloch::updateDelegateKey - newDelegateKey cannot be 0"
        );

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != msg.sender) {
            require(
                !members[newDelegateKey].exists,
                "Moloch::updateDelegateKey - cant overwrite existing members"
            );
            require(
                !members[memberAddressByDelegateKey[newDelegateKey]].exists,
                "Moloch::updateDelegateKey - cant overwrite existing delegate keys"
            );
        }

        Member storage member = members[msg.sender];
        memberAddressByDelegateKey[member.delegateKey] = address(0);
        memberAddressByDelegateKey[newDelegateKey] = msg.sender;
        member.delegateKey = newDelegateKey;

        emit UpdateDelegateKey(msg.sender, newDelegateKey);
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        require(
            guildBank.transfer(recipient, amount),
            "Moloch::withdraw - withdrawal of tokens from guildBank failed"
        );
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

    function getProposalQueueLength() public view returns (uint256) {
        return proposalQueue.length;
    }

    // can only ragequit if the latest proposal you voted YES on has been processed
    function canRagequit(uint256 highestIndexYesVote)
        public
        view
        returns (bool)
    {
        require(
            highestIndexYesVote <= proposalQueue.length &&
                highestIndexYesVote > 0,
            "Moloch::canRagequit - proposal does not exist"
        );
        return proposalQueue[highestIndexYesVote - 1].processed;
    }

    function hasVotingPeriodExpired(uint256 startingPeriod)
        public
        view
        returns (bool)
    {
        return getCurrentPeriod() >= startingPeriod.add(votingPeriodLength);
    }

    function getMemberProposalVote(address memberAddress, uint256 proposalIndex)
        public
        view
        returns (Vote)
    {
        require(
            members[memberAddress].exists,
            "Moloch::getMemberProposalVote - member doesn't exist"
        );
        require(
            proposalIndex < proposalQueue.length,
            "Moloch::getMemberProposalVote - proposal doesn't exist"
        );
        return proposalQueue[proposalIndex].votesByMember[memberAddress];
    }
}

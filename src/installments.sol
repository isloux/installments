// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

contract Installments {
    address private immutable i_payee;
    address private immutable i_payer;
    IERC20 private immutable i_token;
    uint256 private immutable i_totalAmount;
    uint128 private immutable i_startTime;
    uint64 private immutable i_interval;
    uint64 private immutable i_nTotalInstallments;
    uint64 private s_currentInstallment;
    uint8 private s_agreed;

    constructor(
        address _payer,
        address _contractor,
        address _tokenContract,
        uint256 _total,
        uint128 _endTime,
        uint64 _interval
    ) {
        i_payer = _payer;
        i_payee = _contractor;
        i_token = IERC20(_tokenContract);
        i_totalAmount = _total;
        uint128 startTime = uint128(block.timestamp);
        i_nTotalInstallments = uint64(_endTime - startTime) / _interval + 1;
        i_interval = _interval;
        i_startTime = startTime;
    }

    function whichToken() public view returns (address) {
        return address(i_token);
    }

    function getNInstallments() external view returns (uint64) {
        return i_nTotalInstallments;
    }

    function getCurrentInstallment() external view returns (uint64) {
        return s_currentInstallment;
    }

    function agree() external onlyParty {
        // Augmenter la valeur de s_agreed n'est pas idéale ici, car un utiliser peut
        // signer plusieurs fois !
        if (msg.sender == i_payer) s_agreed++;
        else if (msg.sender == i_payee) s_agreed++;
    }

    function getAgreement() public view returns (uint8) {
        return s_agreed;
    }

    modifier agreed() {
        require(s_agreed >= 2);
        _;
    }

    function payInstallment() external agreed {
        require(
            block.timestamp >
                i_startTime + (s_currentInstallment + 1) * i_interval
        );
        uint256 amount = i_totalAmount / i_nTotalInstallments;
        i_token.transfer(i_payee, amount);
        ++s_currentInstallment;
    }

    modifier onlyParty() {
        require(msg.sender == i_payer || msg.sender == i_payee);
        _;
    }

    function revoke() external onlyParty {
        s_agreed = 0;
    }

    function withdraw() external {
        require(msg.sender == i_payer);
        i_token.transfer(i_payer, i_token.balanceOf(address(this)));
    }
}

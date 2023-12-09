// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title OrderManagement
 * @dev The OrderManagement contract provides functionality for order management.
 * All functions are restricted to the owner of the contract. 
 * Orders can be stored, accessed, and finished. 
 */
contract OrderManagement is Ownable {
    
    struct Order {
        bytes32 id;
        address recipient;
        string giftDescription;
    }

    Order[] private orders;

    function viewOrders() public view onlyOwner returns (Order[] memory) {
        return orders;
    }

    /**
    * @dev Internal function for adding order to the orders array.
    * @param recipient Address of the recipient of the gift.
    * @param giftDescription Description of the ordered gift.
    **/
    function addOrder(address recipient, string memory giftDescription) internal onlyOwner  {
        orders.push(Order(keccak256(abi.encode(block.timestamp)), recipient, giftDescription));
    }

    /**
    * @dev Removes order from the orders array.
    * @param orderId The id of the fulfilled order.
    **/
    function finishOrder(bytes32 orderId) public onlyOwner {
        for (uint i = 0 ; i < orders.length; i++) {
            if (orders[i].id == orderId) {
                removeOrder(i);
                return;
            }
        }
    }

    /**
    * @dev Find order id by the recipient address and the gift description.
    * @param recipient Address of the recipient of the gift.
    * @param giftDescription Description of the ordered gift.
    * @return orderId The id of the order.
    **/
    function findOrderId(address recipient, string memory giftDescription) public view onlyOwner returns (bytes32 orderId) {
        for (uint i = 0 ; i < orders.length; i++) {
            if (keccak256(abi.encodePacked(orders[i].recipient, orders[i].giftDescription)) == 
                keccak256(abi.encodePacked(recipient, giftDescription))) {
                return orders[i].id;
            }
        }
        return "";
    }

    /**
    * @dev Private helper function for removing element from array.
    * @param index Array index of the element to remove.
    **/
    function removeOrder(uint index) private {
        for (uint i = index; i < orders.length - 1; i++) {
            orders[i] = orders[i + 1];
        }
        orders.pop();
    }
}

contract CharityToken is OrderManagement {
    
    struct Gift {
        uint price;
        string description;
    }

    mapping (address => uint) private balances;
    
    // Maps gift id with the gift's price and description.
    mapping (uint => Gift) public gifts;
    
    // The exchange rate between real currency and the tokens.
    uint public basisRate;

    // Called when tokens are added to the recipient's balance.
    event TokensSent(address indexed recipient, uint tokens);
    // Called when the basis exchange rate is changed.
    event BasisRateChange(uint basisRate);
    // Called when the tokens are redeemed for a gift.
    event TokensRedeem(uint tokensRedeemed, string gift);

    constructor(uint newBasisRate) {
        basisRate = newBasisRate;
    }

    /**
    * @dev Sets new basis exchange rate, restricted to the owner. 
    * @param newBasisRate New basis rate.
    **/
    function setBasisRate(uint newBasisRate) public onlyOwner {
        basisRate = newBasisRate;
        emit BasisRateChange(basisRate);
    }

    /**
    * @dev Adds new gift to the contract, restricted to the owner. 
    * @param id The human-readable id of the gift.
    **/
    function addGift(uint id, uint price, string memory description) public onlyOwner {
        gifts[id] = Gift(price, description);
    }

    /**
    * @dev Removes a gift from the contract, restricted to the owner. 
    * @param id The human-readable id of the gift.
    **/
    function removeGift(uint id) public onlyOwner {
        delete gifts[id];
    }

    /**
    * @dev Adds tokens to the recipient's balance, restricted to the owner. 
    * @param to The address of the recipient.
    **/
    function sendTokens(address to, uint receivedSum) public onlyOwner {
        uint tokens = receivedSum / basisRate;
        balances[to] += tokens;
        emit TokensSent(to, tokens);
    }

    /**
    * @dev Redeems tokens for a gift. 
    * @param giftId The id of the gift.
    **/
    function redeemTokens(uint giftId) public {
        require(balances[msg.sender] >= gifts[giftId].price, "Token balance is lower than the requested gift price");
        require(bytes(gifts[giftId].description).length > 0, "The gift with this id does not exist");

        balances[msg.sender] -= gifts[giftId].price;
        addOrder(msg.sender, gifts[giftId].description);
        emit TokensRedeem(gifts[giftId].price, gifts[giftId].description);
    }

    /**
    * @dev Checks the amount of tokens on the balance. 
    * @return balance The amount of the tokens available for redeeming.
    **/
    function checkBalance() public view returns (uint256 balance) {
        return balances[msg.sender];
    }
}

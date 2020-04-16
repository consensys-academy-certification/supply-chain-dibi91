// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;


contract SupplyChain {
    address owner;
    // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
    uint itemIdCount;
    // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
    enum State {ForSale, Sold, Shipped, Received}
    // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
    struct Item {
        string name;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }
    // Create a variable named 'items' to map itemIds to Items.
    mapping(uint => Item) items;
    // Create an event to log all state changes for each item.
    event LogChangedEvent(uint itemId, string itemName, State state);

    // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not authorized to call this function."
        );
        _;
    }
    // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
    modifier checkState(uint _itemId, State _stateToCheck) {
        require(
            items[_itemId].state == _stateToCheck,
            "The item is not in the proper status."
        );
        _;
    }
    // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
    modifier checkCaller(address _addressToCheck) {
        require(
            _addressToCheck == msg.sender,
            "You are not authorized to call this function."
        );
        _;
    }
    // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
    modifier checkValue(uint _amount) {
        require(
            msg.value >= _amount,
            "You must sent enough ether to pay the item or fee."
        );
        _;
    }

    //Constructor to set the account owner
    constructor() public {
        owner = msg.sender;
    }

    // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
    function addItem(string memory _name, uint _price)
        public
        payable
        checkValue(1 finney)
    {
        require(_price > 0, "A price greater than 0 is required");
        require(
            keccak256(abi.encodePacked(_name)) !=
                keccak256(abi.encodePacked("")),
            "Non empty item name is required"
        );
        itemIdCount++;
        items[itemIdCount] = Item({
            name: _name,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        if (msg.value > 1 finney) {
            msg.sender.transfer(msg.value - 1 finney);
        }
        emit LogChangedEvent(
            itemIdCount,
            items[itemIdCount].name,
            items[itemIdCount].state
        );
    }

    // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
    function buyItem(uint _itemId)
        public
        payable
        checkState(_itemId, State.ForSale)
    {
        require(
            msg.value >= items[_itemId].price,
            "Not enough wei to buy that item"
        );
        items[_itemId].state = State.Sold;
        items[_itemId].seller.transfer(items[_itemId].price);
        if (msg.value > items[_itemId].price) {
            msg.sender.transfer(msg.value - items[_itemId].price);
        }
        items[_itemId].buyer = msg.sender;
        emit LogChangedEvent(
            _itemId,
            items[itemIdCount].name,
            items[_itemId].state
        );
    }

    // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
    function shipItem(uint _itemId)
        public
        checkCaller(items[_itemId].seller)
        checkState(_itemId, State.Sold)
    {
        items[_itemId].state = State.Shipped;
        emit LogChangedEvent(
            _itemId,
            items[itemIdCount].name,
            items[_itemId].state
        );
    }

    // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
    function receiveItem(uint _itemId)
        public
        checkCaller(items[_itemId].buyer)
        checkState(_itemId, State.Shipped)
    {
        items[_itemId].state = State.Received;
        emit LogChangedEvent(
            _itemId,
            items[itemIdCount].name,
            items[_itemId].state
        );
    }

    // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
    function getItem(uint _itemId)
        public
        view
        returns (string memory, uint, State, address, address)
    {
        return (
            items[_itemId].name,
            items[_itemId].price,
            items[_itemId].state,
            items[_itemId].seller,
            items[_itemId].buyer
        );
    }

    // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
    function withdrawFunds() public payable onlyOwner() {
        msg.sender.transfer(address(this).balance);
    }
}

/*
    This exercise has been updated to use Solidity version 0.5
    Breaking changes from 0.4 to 0.5 can be found here: 
    https://solidity.readthedocs.io/en/v0.5.0/050-breaking-changes.html
*/

pragma solidity ^0.5.0;

/// @author Consensys tutorial
/// @title Supply chain exercise
/// @notice Provides sale and logistic monitoring of products
contract SupplyChain {

  /* set owner */
  address owner;

  /* Add a variable called skuCount to track the most recent sku # */
  uint private skuCount ;

  /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */

   mapping (uint => Item) private items;

  /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
    (declaring them in this order is important for testing)
  */

    enum State { ForSale, Sold, Shipped, Received }

  /* Create a struct named Item.
    Here, add a name, sku, price, state, seller, and buyer
    We've left you to figure out what the appropriate types are,
    if you need help you can ask around :)
    Be sure to add "payable" to addresses that will be handling value transfer
  */

  struct Item{
        string name;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
        uint sku;
  }

  /* Create 4 events with the same name as each possible State (see above)
    Prefix each event with "Log" for clarity, so the forSale event will be called "LogForSale"
    Each event should accept one argument, the sku */

    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

  /// @notice makes sure only the set contract owner can perform a requested operation
   modifier isContractOwner() { // Modifier 
        require(
            msg.sender == owner, "Only the contract owner can call this."
        );
        _;
    }

  /// @notice verifies the caller is a particular address
  /// @param expectedAddress the address used to check against msg.sender
  /// @dev sellers and customers are typically checked to change product status
  modifier verifyCaller (address expectedAddress) { require (msg.sender == expectedAddress); _;}

  /// @notice confirms that the cost of the item is covered
  /// @param price the value to check against the value being sent
  /// @dev excess is allowed and will automatically be refunded
  modifier paidEnough(uint price) { require(msg.value >= price); _;}
  
  /// @notice validates a price is set on the item for sale
  /// @param price amount to validate is greater than 0
  /// @dev this would be the struct value of the sale item 
  modifier hasPrice(uint price) { require(price > 0); _;}
  
  /// @notice converts a string value to bytes and validates it has length
  /// @param name in-memory value to check length against
  /// @dev in memory value
  modifier nameNotEmpty(string memory name) { 
    bytes memory stringInBytes = bytes(name);
    require(stringInBytes.length > 0);
    _;
  }

  /// @notice determines overpayment and refunds the caller
  /// @param sku value used to indicate which product is being used in order to get price
  /// @dev the refund is after the code execution as it is after the _
  modifier checkValue(uint sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint price = items[sku].price;
    uint amountToRefund = msg.value - price;
    items[sku].buyer.transfer(amountToRefund);
  }

  /* For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. 
   Note that the uninitialized Item.State is 0, which is also the index of the ForSale value,
   so checking that Item.State == ForSale is not sufficient to check that an Item is for sale.
   Hint: What item properties will be non-zero when an Item has been added?
   */

  /// @notice va;idates the product is in the correct state with price and seller set and that there is no buyer in order to sell
  /// @param sku used to determine product to check
  /// @dev price is checked on addition so does not need additional checks - buyer must be default address
  modifier forSale(uint sku){
    Item memory item = items[sku];
    require(item.state == State.ForSale);
    require(item.buyer == address(0));
    require(item.seller != address(0)); // this is redundant, and I would probably remove it to save on computation and have a test on addItem to make sure it isn't empty
     _;
  }

  /// @notice validates that a product is in a sold state in order to ship
  /// @param sku used to determine product to check
  /// @dev seller is already checked on forSale and this checks that the buyer is also set
  modifier sold(uint sku){
    Item memory item = items[sku];
    require(item.state == State.Sold);
    require(item.buyer != address(0));
    require(item.seller != address(0)); // this is redundant, and I would probably remove it to save on computation and have a test on addItem to make sure it isn't empty
     _;
  }

  /// @notice validates the product is in a shipped state 
  /// @param sku used to determine product to check
  /// @dev purely a state check if you could consider the other fields validated elsewhere
  modifier shipped(uint sku){
    Item memory item = items[sku];
     require(item.state == State.Shipped);
     require(item.seller != address(0)); // this is redundant, and I would probably remove it to save on computation and have a test on addItem to make sure it isn't empty
     require(item.buyer != address(0));
     _;
  }

  /// @notice validates the product has been marked as receivd
  /// @param sku used to determine product to check
  /// @dev purely a state check if you could consider the other fields validated elsewhere
  modifier received(uint sku){
    Item memory item = items[sku];
     require(item.state == State.Received);
     require(item.seller != address(0)); // this is redundant, and I would probably remove it to save on computation and have a test on addItem to make sure it isn't empty
     require(item.buyer != address(0));
     _;
  }

  /// @notice constructs the contract
  /// @dev sets the owner of the contract and default skuCount to 0 (it is default, but setting anyway)
  constructor() public {
    /* Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
        owner = msg.sender; 
        skuCount = 0;
  }

   /// @notice fallback function for unexpected payments 
   /// @dev reverts payment if funds accidentally set without a function specific call
   function () external payable {
        revert();
   } 

  /// @notice adds an item to the items array
  /// @param name of product
  /// @param price of product
  /// @return a bool indicating success
  /// @dev validates name and price are set and emits the LogForSale event and then adds to new item
  function addItem(string memory name, uint price) public nameNotEmpty(name) hasPrice(price) returns(bool){
    emit LogForSale(skuCount);

    items[skuCount] = Item({name: name, sku: skuCount, price: price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;

    return true;
  }

  /* Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. Remember to call the event associated with this function!*/

  /// @notice adds an item to the items array
  /// @param sku product identifier
  /// @dev validates for sale state, adequate (or exccess) payment and emits LogSold if successful
  function buyItem(uint sku) public payable forSale(sku) paidEnough(sku) checkValue(sku){
    Item storage item  = items[sku];
    
    item.buyer = msg.sender;
    item.state = State.Sold;
    item.seller.transfer(item.price);

    emit LogSold(sku);
  }

  /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/

  /// @notice marks a product as being shipped
  /// @param sku product identifier
  /// @dev validates sold state and that the caller is the product seller - emits LogShipped if successful
  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
      Item storage item  = items[sku];
      item.state = State.Shipped;
     emit LogShipped(sku);
  }

  /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
  
  /// @notice marks a product as being received
  /// @param sku product identifier
  /// @dev validates shipped state and that the caller is the product buyer - emits LogShipped if successful
  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer){
    Item storage item  = items[sku];
    item.state = State.Received;
    emit LogReceived(sku);
  }

  // should we restrict this to "isContractOwner" ? tests pass with it on.

  /* We have these functions completed so we can run tests, just ignore it :) */
  /// @dev - ignored, but would comment if it was used for more than just tests
  function fetchItem(uint _sku) public  view  returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}

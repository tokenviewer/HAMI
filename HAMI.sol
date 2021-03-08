pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Utils.sol";

contract Hubble {

  enum BonusType {RecommendBonus, NodeBonus, ManageBonus}

  enum BonusCoe {RecommendCoe, NodeCoeV1, NodeCoeV2, NodeCoeV3, NodeCoeV3C}

  struct Node {
    bool exist;
    uint registeredAt;
    uint upgradedAt;
    uint id;
    uint referrerID;
    uint placeID;
    address addr;
    uint16 buyPrice;
    uint8 priceLevel;
    uint8 nodeLevel;
    uint[] referrals;
    uint[] children;
    uint[] pending;
  }

  struct PriceLevel {
    uint16 price;
    bool noBurning;
  }

  struct Account {
    uint earned;
    uint available;
  }

  mapping(address => Account) appAccounts;

  // coe/10000
  mapping(uint => uint16) public appBonusCoe;
  mapping(uint8 => uint16[]) appMngBonusCoe;
  uint8 public appMngReferralsCount;

  uint public appUserID;
  mapping(uint => Node) appUsers;
  mapping(address => uint) appAddr2ID;
  mapping(uint8 => PriceLevel) public appLevelPrices;
  uint8 public appMaxPriceLevel;

  ERC20 public token;

  address public founder;

  bool public paused;

  modifier whenNotPaused() {
    require(!paused, "Pausable: paused");
    _;
  }

  event Register(address indexed user, uint id, uint referrerID, uint8 priceLevel, uint buyPrice);
  event Upgrade(address indexed user, uint id, uint8 priceLevel, uint buyPrice);
  event GotBonus(address indexed user, uint id, uint amount, uint8 decimals, BonusType t);
  event Place(address indexed user, uint id, uint placeID, uint idx, bool pending);
  event Claim(address indexed user, uint amount);

  function register(uint referrerID, uint8 priceLevel) public whenNotPaused {
    _register(msg.sender, referrerID, priceLevel, false);
  }

  function upgrade(uint8 priceLevel) public whenNotPaused {
    _upgrade(msg.sender, priceLevel);
  }

  function getNodeExtraData(uint id) public view returns (uint[] memory referrals, uint[] memory children, uint[] memory pending) {
    require(appUsers[id].exist, "user does not exist");
    return (appUsers[id].referrals, appUsers[id].children, appUsers[id].pending);
  }

  function getUserByID(uint user) public view returns (bool exist, uint id, uint referrerID, uint placeID, address addr, uint8 priceLevel, uint buyPrice, uint8 nodeLevel, uint registeredAt, uint upgradedAt) {
    Node memory node = appUsers[user];
    return (
    node.exist,
    node.id,
    node.referrerID,
    node.placeID,
    node.addr,
    node.priceLevel,
    node.buyPrice,
    node.nodeLevel,
    node.registeredAt,
    node.upgradedAt
    );
  }

  function getUser(address user) public view returns (bool exist, uint id, uint referrerID, uint placeID, address addr, uint8 priceLevel, uint buyPrice, uint8 nodeLevel, uint registeredAt, uint upgradedAt) {
    return getUserByID(appAddr2ID[user]);
  }

  function getBonusCoe(BonusCoe t) public view returns (uint) {
    return uint(appBonusCoe[uint(t)]);
  }

  function getMaxMngBonusLevel() public view returns (uint max) {
    for (uint8 i = 1; i < appMaxPriceLevel; i++) {
      if (appMngBonusCoe[i].length > max) {
        max = appMngBonusCoe[i].length;
      }
    }
    return max;
  }

  function getMngBonusCoe(uint8 level) public view returns (uint16[] memory) {
    return appMngBonusCoe[level];
  }

  function getAccount(address user) public view returns (uint earned, uint available) {
    Account memory account = appAccounts[user];
    return (account.earned, account.available);
  }

  function claim(uint amount) public whenNotPaused {
    require(appAccounts[msg.sender].available >= amount, "insufficient balance");
    appAccounts[msg.sender].available -= amount;
    token.transfer(msg.sender, amount);
    emit Claim(msg.sender, amount);
  }

  receive() external payable {
    revert();
  }

}

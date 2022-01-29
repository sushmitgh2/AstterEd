// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/AstterToken.sol";

contract AstterCore {
  struct Video{
     uint256 id;
     string name;
     string url;
     uint256 duration;
  }

  struct Subscription{
      string name;
      string cover_photo;
      uint256 timestamp;
      uint256 vidCount;
      Video[] videos;
  }

  uint256 subId;
  uint256 userId;
  address owner;
  IERC20 private Astter;
  IERC20 private USDC;

  event UserAdded(address indexed _user, uint256 timestamp);
  event SubscriptionAdded(uint256 indexed _subId, string name, uint256 timestamp);
  event SubscriptionPurchased(address indexed _user, uint256 indexed _subId, uint256 timestamp);

  mapping(address => uint256) users; 
  mapping(uint => Subscription) subscriptionsAvailable;
  mapping(address => uint256) subscriptionsBoughtByUser;

  modifier onlyOwner() {
     require(msg.sender == owner, "Only owner of the contract can make edits");
     _;
  }

  constructor() {
      subId = 0;
      userId = 0;
      owner = msg.sender;
      USDC = Token(0x5425890298aed601595a70AB815c96711a31Bc65);
      Astter = Token(0x5425890298aed601595a70AB815c96711a31Bc65);
  }

  function addUser() external {
    users[msg.sender] = userId;
    emit UserAdded(msg.sender, block.timestamp);
    userId++;
  }

  function addSubscription(string memory _name, string memory _cover_photo) external onlyOwner{
     Subscription storage sub = subscriptionsAvailable[subId];
     sub.name = _name;
     sub.cover_photo = _cover_photo;
     sub.timestamp = block.timestamp;
     sub.vidCount = 0;

     emit SubscriptionAdded(subId, _name, block.timestamp);
     subId++;
  }

  function addVideos(uint256 _sub, string memory _name, string memory _url, uint256 _duration) external onlyOwner{
     Subscription storage sub = subscriptionsAvailable[_sub];
     sub.videos.push(Video(sub.vidCount, _name, _url, _duration));
     sub.vidCount++;
  }

  function getVideos(uint256 _sub) external view returns(Video[] memory){
     return subscriptionsAvailable[_sub].videos;
  }

  function buySubscription(uint256 _userId, uint256 _subId) external payable{
     uint256 allowance = USDC.allowance(msg.sender, address(this));
     require(allowance >= 500 * (10 ** 18), "Check the token allowance");
     USDC.transferFrom(msg.sender, address(this), 500 * (10 ** 18));
     Astter.mint(msg.sender, 500 * (10 ** 18));
  }

  function getBalance() external returns(uint256){
     Astter.balanceOf(msg.sender);
  }
}

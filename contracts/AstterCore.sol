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

  struct Course{
      string name;
      string cover_photo;
      uint256 timestamp;
      uint256 vidCount;
      Video[] videos;
  }

  uint256 userId;
  uint256 courseId;
  address owner;
  uint averageCompletionDay;
  Token private Astter;
  Token private USDC;

  event UserAdded(address indexed _user, uint256 timestamp);
  event CourseAdded(uint256 indexed _subId, string name, uint256 timestamp);
  event SubscriptionPurchased(address indexed _user, uint256 timestamp);

  mapping(address => uint256) users; 
  mapping(uint => Course) courses;
  Course[] coursesArr;
  mapping(address => uint) userSubscribed;

  mapping(address => uint256) staked;
  mapping(address => uint256) dateOfStaking;
  mapping(address => mapping(uint => uint)) completed;
  mapping(address => uint) completedCount;
  mapping(string => uint) treasury; 

  modifier onlyOwner() {
     require(msg.sender == owner, "Only owner of the contract can make edits");
     _;
  }

  constructor() {
      userId = 0;
      courseId = 0;
      owner = msg.sender;
      averageCompletionDay = 1036800000;
      USDC = Token(0x08a978a0399465621e667C49CD54CC874DC064Eb);
      Astter = Token(0xFe9085EB365A4807974FD76335605B939F57168f);

      treasury["staked"] = 0;
      treasury["deposit"] = 0;
  }

  function addUser() external {
    users[msg.sender] = userId;
    emit UserAdded(msg.sender, block.timestamp);
    userId++;
  }

  function addCourse(string memory _name, string memory _cover_photo) external onlyOwner{
     Course storage sub = courses[courseId];
     sub.name = _name;
     sub.cover_photo = _cover_photo;
     sub.timestamp = block.timestamp;
     sub.vidCount = 0;

     coursesArr.push(sub);
     emit CourseAdded(courseId, _name, block.timestamp);
     courseId++;
  }

  function addVideos(uint256 _course, string memory _name, string memory _url, uint256 _duration) external onlyOwner{
     Course storage sub = courses[_course];
     sub.videos.push(Video(sub.vidCount, _name, _url, _duration));
     sub.vidCount++;
  }

  function getVideos(uint256 _sub) external view returns(Video[] memory){
     return courses[_sub].videos;
  }

  function buySubscription() external{
     uint256 subAmount = 100 * (10 ** USDC.decimals());

     USDC.transferFrom(msg.sender, address(this), subAmount);
     treasury["deposit"] = treasury["deposit"] + subAmount;

     Astter.approve(msg.sender, subAmount);
     Astter.transfer(msg.sender, subAmount);

     treasury["staked"] = subAmount;
     staked[msg.sender] = subAmount;
     dateOfStaking[msg.sender] = block.timestamp;

     userSubscribed[msg.sender] = 1;
     emit SubscriptionPurchased(msg.sender, block.timestamp);
  }

  function completeCourse(uint _courseId) external onlyOwner {
     require(courseId > 0, "Courses have not been initialized");
     require(completed[msg.sender][_courseId] == 1, "Course has already been completed");
     completed[msg.sender][_courseId] = 1;
     completedCount[msg.sender]++;
  }

  function currentReward(address _user) public view returns(uint) {
     uint256 stakedDays = block.timestamp - dateOfStaking[_user];
     uint256 calculatedReward = staked[_user] * ((averageCompletionDay * completedCount[_user])/stakedDays) * (treasury["staked"] / Astter.balanceOf(address(this)));
     return calculatedReward;
  }

  function unstake() external {
     uint calculatedReward = currentReward(msg.sender);
     uint stakedAmount = staked[msg.sender];

     Astter.approve(msg.sender, calculatedReward + stakedAmount);
     Astter.transfer(msg.sender, calculatedReward + stakedAmount);

     staked[msg.sender] = 0;
      
  }

  function withdrawReward() external {
     uint calculatedReward = currentReward(msg.sender);

     Astter.approve(msg.sender, calculatedReward);
     Astter.transfer(msg.sender, calculatedReward);
  }

  function getUserStaked(address _user) external view returns(uint) {
     return staked[_user];
  }

  function getTotalStaked() external view returns (uint) {
     return treasury["staked"];
  }

  function getTotalDeposited() external view returns(uint) {
     return treasury["deposit"];
  }

  function getTotalAstterSupply() external view returns(uint) {
     return Astter.totalSupply();
  }

   function getAstterBalanceOfContract() external view returns(uint) {
      return Astter.balanceOf(address(this));
   }

   function getSubscriptionStatus(address _user) external view returns(uint) {
      return userSubscribed[_user];
   }

   function withdrawLiquidity() external onlyOwner{
      Astter.approve(owner, Astter.balanceOf(address(this)));
      Astter.transfer(owner, Astter.balanceOf(address(this)));
   }

}

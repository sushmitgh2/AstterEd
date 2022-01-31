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
      USDC = Token(0xa131AD247055FD2e2aA8b156A11bdEc81b9eAD95);
      Astter = Token(0xd9145CCE52D386f254917e481eB44e9943F39138);
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


  function unstake() external {
     uint256 stakedDays = block.timestamp - dateOfStaking[msg.sender];
     uint256 calculatedReward = staked[msg.sender] * ((averageCompletionDay * completedCount[msg.sender])/stakedDays) * (treasury["staked"] / Astter.balanceOf(address(this)));

     Astter.approve(msg.sender, calculatedReward);
     Astter.transfer(msg.sender, calculatedReward);

     staked[msg.sender] = 0;
      
  }

  function currentReward() external view returns(uint) {
     uint256 stakedDays = block.timestamp - dateOfStaking[msg.sender];
     uint256 calculatedReward = staked[msg.sender] * ((averageCompletionDay * completedCount[msg.sender])/stakedDays) * (treasury["staked"] / Astter.balanceOf(address(this)));
     return calculatedReward;
  }

}

pragma solidity >=0.5.0 <0.6.8;


interface daiErc20 {
   function approve(address, uint256) external returns (bool);
   function transfer(address, uint256) external returns (bool);
   function transferFrom(address src, address dst, uint wad) external returns (bool);
   function balanceOf(address) external view  returns (uint256 balance);
}


interface CompoundErc20 {
    function mint(uint256) external returns (uint256);

   // function exchangeRateCurrent() external returns (uint256);

   // function supplyRatePerBlock() external returns (uint256);

   function redeem(uint) external returns (uint);

  //  function redeemUnderlying(uint) external returns (uint);
  function balanceOf(address owner) external view returns (uint);
}



contract bedium{
    
    daiErc20 dai=daiErc20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    CompoundErc20 compound=CompoundErc20(0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD);
    
    uint totalPost;
    address owner;
    
    //Post Details
    mapping(uint=>address) postAuthor;
    //mapping(uint=>string) postAuthorName;
    mapping(uint=>string) postHash;
    mapping(uint=>string) imageHash;
    mapping(uint=>string) postTitle;
   
    
   //User Details
    mapping(address=>string) userName;
    mapping(address=>string) userImage;
    mapping(address=>string) userCoverImage;
    mapping(address=>bool) userStatus;
    mapping(address=>uint[]) userPostsList;
    mapping(address=>uint) totalUserPosts;
    mapping(address=>uint) subscriptionPeriod;
    
    constructor() public{
       owner=msg.sender; 
    }
//******************************************POST FUNCTIONS*********************************************************************
    function setNewPost(string memory _fileHash, string memory _imageHash, string memory _title ) public returns(uint){
        postAuthor[++totalPost]=msg.sender;
        postHash[totalPost]=_fileHash;
        imageHash[totalPost]=_imageHash;
        postTitle[totalPost]=_title;
        userPostsList[msg.sender].push(totalPost);
        totalUserPosts[msg.sender]+=1;
        return totalPost;
    }
    
    function getPost(uint _id) public view returns(uint, address, string memory,string memory ,string memory, string memory){
        return (_id, postAuthor[_id], postHash[_id], imageHash[_id], postTitle[_id], userName[postAuthor[_id]]);
    }
    
    function getTotalPost() public view returns(uint){
        return totalPost;
    }
    
    
        // function updatePost(uint id, string memory hash) public returns(bool){
    //     if(totalPost>=id && postAuthor[id]==msg.sender){
    //          postHash[id]=hash;
    //          return(true);
    //     }
    //     return false;
    // }
    
    // function UpdateAuthor(uint id,string memory name) public returns(bool){
    //     if(bytes(postHash[id]).length!=0 && postAuthor[id]==msg.sender){
    //     authorName[id]=name;
    //     return(true);
    //     }
    //     return false;
    // }
    
    
//**********************************************USER FUNTIONS*************************
    function getUserTotalPosts(address _user) public view returns(uint){
        return totalUserPosts[_user];
    }
     
    function getUserPostsArray(address _user) public view returns(uint[] memory){
        return userPostsList[_user];
    }
    
    function setUserName(string memory _name) public{
        userName[msg.sender]=_name;
    }
    
    function setUserImage(string memory _hash) public{
        userImage[msg.sender]=_hash;
    }
    
    function setCoverImage(string memory _hash) public{
        userCoverImage[msg.sender]=_hash;
    }
    
    function getUserDetails(address _user) public view returns(string memory, string memory, string memory){
        return(userName[_user], userImage[_user], userCoverImage[_user]);
    }
    
    function CheckAuthorOwner(uint _id) public view returns(bool){
        if(msg.sender==owner || msg.sender==postAuthor[_id]){
            return true;
        }
        else{
            return false;
        }
    }
    
    function checkSubscribed() public view returns(bool){
        if(block.timestamp>subscriptionPeriod[msg.sender]){
            return false;
        }
      return true;
    }    

    function getSubscriptionPeriod() public view returns(uint){
        return subscriptionPeriod[msg.sender];
    }
    
    function transferSubscription(address _to) public{
        require(subscriptionPeriod[_to]<subscriptionPeriod[msg.sender]);
        subscriptionPeriod[_to]=subscriptionPeriod[msg.sender];
        subscriptionPeriod[msg.sender]=0;
    }
    
    
    function transferDai(uint _amount) public returns(bool){
        dai.transferFrom(msg.sender,address(this),_amount);
        subscriptionPeriod[msg.sender]=block.timestamp+30 days;
        dai.approve(address(compound), _amount);
        uint mintResult = compound.mint(_amount);
        return true;
    }   

    

    
    function MyCTokensBalance() public view returns(uint256){
        require(msg.sender==owner);
        return compound.balanceOf(address(this));
    }
    
    function Balance() public view returns(uint256){
         require(msg.sender==owner);
         return dai.balanceOf(address(this));
    }    
    
    function redeemToOwner(uint _amount) public returns(bool){
        require(msg.sender==owner);
        compound.redeem(_amount);
        dai.transfer(owner,Balance());
        return true;
    }
    
    mapping(address=>uint) internal likes;
    mapping(address=>bool) internal status;
    mapping(address=>uint) internal paidTime ;
    mapping(address=>uint) internal PaidAmount;
    uint internal totalAuthors;
    function getPaid(uint _likes) public returns(bool){
        require(_likes>10);
        likes[msg.sender]=_likes;
        require(paidTime[msg.sender]+30 days<=block.timestamp);
        if(!status[msg.sender]){
        status[msg.sender]=true;
        ++totalAuthors;
        paidTime[msg.sender]=block.timestamp;
        uint256 balance=compound.balanceOf(address(this))/uint256(totalAuthors);
        compound.redeem(balance);
        PaidAmount[msg.sender]+=Balance();
        dai.transfer(msg.sender,Balance());
        }
        else
        {
        paidTime[msg.sender]=block.timestamp;
        uint256 balance=compound.balanceOf(address(this))/uint256(totalAuthors);
        compound.redeem(balance);
        PaidAmount[msg.sender]+=Balance();
        dai.transfer(msg.sender,Balance());
        }

        return true;
    }  
    
  function getNextPayTime() public view returns(uint){
        return paidTime[msg.sender]+30 days;
    }
    
  function getPaidAmount() public view returns(uint){
        return PaidAmount[msg.sender];
    }   
    
  function getPAYDetails() public view returns(uint, bool, uint){
      return(likes[msg.sender], status[msg.sender],totalAuthors);
  }    
    
    
    // function transferToCompound(uint _amount) public returns(bool){
    //  dai.approve(address(compound), _amount);
    //   uint mintResult = compound.mint(_amount);
    //   return true;
    // }    
    
}
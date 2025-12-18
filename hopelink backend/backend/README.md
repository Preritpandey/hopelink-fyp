# CHARITY-APP-BACKEND

## Usages

1. Open terminal
2. git clone https://github.com/acharyasuyog/charity-backend.git [ctrl & ctrl+v]
3. cd CHARITY-BACKEND [ctrl & ctrl+v]
4. npm install [ctrl & ctrl+v]
5. npm run dev [ctrl & ctrl+v]

Kudos 🎉🎉. Good to go now 👏🏽👏🏽. Test api using postman.

## API DESCRIPTION

## Authentication

```perl
POST : /api/v1/auth/register

payload: {
   username: "suyognotnice@gmail.com"
  password:"Test@123"
  role:"user"-> user, organization
}

****** -> Response  <- *******
onSuccess: {
  message: 'Register succesfull !!',
 email:"suyognotnice@gmail.com"
}
onFailure: {
  message: 'Register failed !!',
  token: null,
}
```

```perl
POST : /api/v1/auth/login

payload: {
   username: "suyognotnice@gmail.com"
  password:"Test@123"
}

****** -> Response  <- *******
onSuccess: {
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzZhMzFlOTMzNTUwMTMyMGQ5YmUyZGMiLCJyb2xlIjoib3JnYW5pemF0aW9uIiwiaWF0IjoxNzM1MjY5OTg1LCJleHAiOjE3Mzc4NjE5ODV9.B9xmuEvlrvFxtOzRhWccQm-14f-1R_Qqp2FHTjvWmhc"

}
onFailure: {
    "success": false,
    "message": "Invalid credentials"
}
```

```perl
PUT : /api/v1/auth/uploadProfileImage

payload:{
  "token":"retrieved from login",

  formData: {
    "profileImage": "https://example.com/images/profile.jpg"
  }
  onSuccess:{
{
    "success": true,
    "message": "Profile image uploaded successfully",
    "data": {
        "name": "John Doe",
        "email": "john.doe@example.com",
        "profileImage": "https://example.com/path/to/profile-image.jpg"
    }
}
}

onFailure:{ success: false,
 message: "Couldn't upload profile image" }
```

````perl

}

## Campaign

```perl
POST : /api/v1/campaign
payload:{
    "title": "Save the Forest Campaign",
    "description": "A crowdfunding campaign to protect and preserve the rainforest.",
    "totalFund": 100000,
    "currentFund": 45000,
    "fundDate": "2024-12-25",
    "fundTime": "15:00",
    "totalFundPercentage": 45,
    "fundImage": "https://example.com/images/fund-campaign.jpg",
    "category":"676a32f729889e02a1dae4da",
    "participants": []
}

onSuccess:{
    "success": true,
    "data": {
        "title": "Save the Forest Campaign",
        "description": "A crowdfunding campaign to protect and preserve the rainforest.",
        "totalFund": 100000,
        "currentFund": 45000,
        "fundDate": "2024-12-25T00:00:00.000Z",
        "fundTime": "15:00",
        "totalFundPercentage": 45,
        "fundImage": "https://example.com/images/fund-campaign.jpg",
        "postedBy": "67639938b05bb4ca9aeb92fa",
        "category": "676a32f729889e02a1dae4da",
        "participants": [],
        "_id": "676e1fae6d7b64c281a4110c",
        "createdAt": "2024-12-27T03:31:58.593Z",
        "updatedAt": "2024-12-27T03:31:58.593Z",
        "__v": 0
    }
}

onFailure:{
    "success": false,
    "message": "Campaign creation failed"
}
````

## Donation

```perl

POST : api/v1/donation

payload: {
"userId":"retrieved from token",
"amount": 100,
campaignId: "5f7b4b3b7f3b3b3b3b3b3b3b",
paymentId: "esewa/khalti id",
status: "success" // pending, success, failed
}

**\*\*** -> Response <- **\*\*\***
onSuccess: {
message: 'Donation successfull !!',
amount: 100,
campaignId: "5f7b4b3b7f3b3b3b3b3b3b3b",
paymentId: "esewa/khalti id",
status: "success"
}

onFailure: {
message: 'Donation failed !!',
status: "failed"
}

```

```perl

GET : api/v1/donation

payload: {
userId:"retrieved from token",
}

**\*\*** -> Response <- **\*\*\***
onSuccess: {
message: 'Donation successfull !!',
amount: 100,
campaignId: "5f7b4b3b7f3b3b3b3b3b3b3b",
paymentId: "esewa/khalti id",
status: "success"
}

onFailure: {
message: 'Donation failed !!',
status: "failed"
}

```

```perl

GET : api/v1/donation/:campaignId

payload: {
userId:"retrieved from token",
}

**\*\*** -> Response <- **\*\*\***

onSuccess: {
message: 'Donation successfull !!',
amount: 100,
campaignId: "5f7b4b3b7f3b3b3b3b3b3b3b",
paymentId: "esewa/khalti id",
status: "success"
}

onFailure: {
message: 'Donation failed !!',
status: "failed"
}

```

# Community Resource Sharing Platform

This smart contract is a **decentralized platform** for **community members to share tools, equipment, and resources**. It enables users to **list, borrow, return, and rate** shared items in a trust-driven, peer-to-peer environment. This solution promotes **resource efficiency**, **cost savings**, and **community collaboration**.

---

## Features

###  List Resources

Owners can list resources with details such as:

* Name, category, description, location, and condition
* Daily rental rate
* Availability status

###  Borrow Resources

Users can:

* Browse and borrow available resources
* Pay for usage based on a specified duration
* Ensure item return is tracked via a borrowing record

###  Return Resources

* Borrowers return items
* Resources are marked available again for others to use

###  Rate Resources

* After returning an item, borrowers can rate it
* Ratings include a score (1 to 5) and a comment
* Ratings improve trust and resource quality tracking

### User Profiles

Each user has a profile with:

* Name and verification status
* Reputation score
* Stats on total items lent, borrowed, earned, and spent

###  Admin Verification

* The contract owner can verify users
* Verified users receive a reputation score boost

---

## Data Structures

* **resources**: Maps each resource by ID and stores ownership, details, and status.
* **borrowing-records**: Tracks each borrowing instance including cost, duration, and return status.
* **user-profiles**: Maintains user activity stats and reputation.
* **resource-ratings**: Stores ratings and feedback from users after use.

---

## Smart Contract Constants

| Constant               | Purpose                             |
| ---------------------- | ----------------------------------- |
| `CONTRACT_OWNER`       | Stores the admin address            |
| `ERR_UNAUTHORIZED`     | Unauthorized access error           |
| `ERR_NOT_FOUND`        | Resource or record not found        |
| `ERR_ALREADY_BORROWED` | Resource already returned or rated  |
| `ERR_NOT_AVAILABLE`    | Resource is not currently available |
| `ERR_INVALID_DURATION` | Invalid duration or rating value    |
| `ERR_OVERDUE`          | Resource return is overdue          |
| `ERR_NOT_BORROWER`     | Caller is not the original borrower |

---

## Public Functions

### `list-resource(...)`

Creates a new resource entry and updates the user’s lending stats.

### `borrow-resource(resource-id, duration-days)`

Allows a user to borrow an available resource, creates a borrowing record, and updates profiles.

### `return-resource(record-id)`

Marks a borrowed resource as returned and makes it available again.

### `rate-resource(record-id, rating, comment)`

Allows a borrower to rate a resource post-return. Only one rating per borrowing allowed.

### `update-profile(name)`

Updates a user's profile with a display name.

### `verify-user(user)`

Admin-only function to verify and boost a user’s reputation.

---

## Read-Only Functions

### `get-resource(resource-id)`

Returns the full details of a listed resource.

### `get-borrowing-record(record-id)`

Fetches a specific borrowing record.

### `get-user-profile(user)`

Returns a user's profile stats and verification status.

### `get-resource-rating(rating-id)`

Returns a specific rating's data.

### `get-platform-stats()`

Provides platform-wide stats:

* Total resources
* Total transactions
* Total borrowing records
* Total ratings

### `is-resource-available(resource-id)`

Checks if a resource is currently available.

### `is-borrowing-overdue(record-id)`

Checks if a borrowing record is overdue (based on block height and return status).

---

## Development Notes

* **Block-height** is used for calculating borrowing duration and determining overdue status.
* **All counters** (`resource-counter`, `record-counter`, `rating-counter`) are auto-incremented and ensure unique IDs.
* **User profiles** are automatically created or updated on interaction.

---

## Suggested Improvements

* Add token-based payments or incentives
* Include dispute resolution mechanism
* Add support for image or media file storage
* Allow owners to set resource availability schedule
ree to fork this contract, test it on Clarity testnets, and submit pull requests or suggestions for improvement.

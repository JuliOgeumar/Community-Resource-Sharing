;; Community Resource Sharing Platform
;; Enables neighbors to share tools, equipment, and resources

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_BORROWED (err u102))
(define-constant ERR_NOT_AVAILABLE (err u103))
(define-constant ERR_INVALID_DURATION (err u104))
(define-constant ERR_OVERDUE (err u105))
(define-constant ERR_NOT_BORROWER (err u106))
(define-constant ERR_INVALID_INPUT (err u107))
(define-constant ERR_INVALID_RATING (err u108))

;; Data structures
(define-map resources
  { resource-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    category: (string-ascii 50),
    description: (string-ascii 200),
    daily-rate: uint,
    available: bool,
    location: (string-ascii 100),
    condition: (string-ascii 20),
    created-at: uint
  }
)

(define-map borrowing-records
  { record-id: uint }
  {
    resource-id: uint,
    borrower: principal,
    owner: principal,
    start-block: uint,
    end-block: uint,
    daily-rate: uint,
    total-cost: uint,
    returned: bool,
    rating-given: bool
  }
)

(define-map user-profiles
  { user: principal }
  {
    name: (string-ascii 50),
    reputation-score: uint,
    total-lends: uint,
    total-borrows: uint,
    total-earned: uint,
    total-spent: uint,
    verified: bool
  }
)

(define-map resource-ratings
  { rating-id: uint }
  {
    resource-id: uint,
    borrower: principal,
    rating: uint,
    comment: (string-ascii 200),
    timestamp: uint
  }
)

;; Data variables
(define-data-var resource-counter uint u0)
(define-data-var record-counter uint u0)
(define-data-var rating-counter uint u0)
(define-data-var total-transactions uint u0)

;; Input validation functions
(define-private (is-valid-name (name (string-ascii 100)))
  (and (> (len name) u0) (<= (len name) u100))
)

(define-private (is-valid-category (category (string-ascii 50)))
  (and (> (len category) u0) (<= (len category) u50))
)

(define-private (is-valid-description (description (string-ascii 200)))
  (and (> (len description) u0) (<= (len description) u200))
)

(define-private (is-valid-location (location (string-ascii 100)))
  (and (> (len location) u0) (<= (len location) u100))
)

(define-private (is-valid-condition (condition (string-ascii 20)))
  (and (> (len condition) u0) (<= (len condition) u20))
)

(define-private (is-valid-daily-rate (rate uint))
  (and (> rate u0) (<= rate u1000)) ;; Max $10 per day
)

(define-private (is-valid-duration (days uint))
  (and (> days u0) (<= days u365)) ;; Max 1 year
)

(define-private (is-valid-resource-id (resource-id uint))
  (and (> resource-id u0) (<= resource-id (var-get resource-counter)))
)

(define-private (is-valid-record-id (record-id uint))
  (and (> record-id u0) (<= record-id (var-get record-counter)))
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

(define-private (is-valid-comment (comment (string-ascii 200)))
  (<= (len comment) u200)
)

(define-private (is-valid-profile-name (name (string-ascii 50)))
  (and (> (len name) u0) (<= (len name) u50))
)

;; Public functions

;; List a new resource for sharing
(define-public (list-resource (name (string-ascii 100)) (category (string-ascii 50)) (description (string-ascii 200)) (daily-rate uint) (location (string-ascii 100)) (condition (string-ascii 20)))
  (let
    (
      (resource-id (+ (var-get resource-counter) u1))
      (user-profile (default-to 
        { name: "", reputation-score: u100, total-lends: u0, total-borrows: u0, total-earned: u0, total-spent: u0, verified: false }
        (map-get? user-profiles { user: tx-sender })
      ))
    )
    ;; Input validation
    (asserts! (is-valid-name name) ERR_INVALID_INPUT)
    (asserts! (is-valid-category category) ERR_INVALID_INPUT)
    (asserts! (is-valid-description description) ERR_INVALID_INPUT)
    (asserts! (is-valid-daily-rate daily-rate) ERR_INVALID_DURATION)
    (asserts! (is-valid-location location) ERR_INVALID_INPUT)
    (asserts! (is-valid-condition condition) ERR_INVALID_INPUT)
    
    ;; Store resource
    (map-set resources
      { resource-id: resource-id }
      {
        owner: tx-sender,
        name: name,
        category: category,
        description: description,
        daily-rate: daily-rate,
        available: true,
        location: location,
        condition: condition,
        created-at: stacks-block-height
      }
    )
    
    ;; Update user profile
    (map-set user-profiles
      { user: tx-sender }
      (merge user-profile { total-lends: (+ (get total-lends user-profile) u1) })
    )
    
    (var-set resource-counter resource-id)
    (ok resource-id)
  )
)

;; Borrow a resource
(define-public (borrow-resource (resource-id uint) (duration-days uint))
  (let
    (
      (resource (unwrap! (map-get? resources { resource-id: resource-id }) ERR_NOT_FOUND))
      (record-id (+ (var-get record-counter) u1))
      (total-cost (* (get daily-rate resource) duration-days))
      (end-block (+ stacks-block-height (* duration-days u144))) ;; Approximate blocks per day
      (borrower-profile (default-to 
        { name: "", reputation-score: u100, total-lends: u0, total-borrows: u0, total-earned: u0, total-spent: u0, verified: false }
        (map-get? user-profiles { user: tx-sender })
      ))
      (owner-profile (default-to 
        { name: "", reputation-score: u100, total-lends: u0, total-borrows: u0, total-earned: u0, total-spent: u0, verified: false }
        (map-get? user-profiles { user: (get owner resource) })
      ))
    )
    ;; Input validation
    (asserts! (is-valid-resource-id resource-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-duration duration-days) ERR_INVALID_DURATION)
    (asserts! (get available resource) ERR_NOT_AVAILABLE)
    (asserts! (not (is-eq tx-sender (get owner resource))) ERR_UNAUTHORIZED)
    
    ;; Mark resource as unavailable
    (map-set resources
      { resource-id: resource-id }
      (merge resource { available: false })
    )
    
    ;; Create borrowing record
    (map-set borrowing-records
      { record-id: record-id }
      {
        resource-id: resource-id,
        borrower: tx-sender,
        owner: (get owner resource),
        start-block: stacks-block-height,
        end-block: end-block,
        daily-rate: (get daily-rate resource),
        total-cost: total-cost,
        returned: false,
        rating-given: false
      }
    )
    
    ;; Update user profiles
    (map-set user-profiles
      { user: tx-sender }
      (merge borrower-profile { 
        total-borrows: (+ (get total-borrows borrower-profile) u1),
        total-spent: (+ (get total-spent borrower-profile) total-cost)
      })
    )
    
    (map-set user-profiles
      { user: (get owner resource) }
      (merge owner-profile { 
        total-earned: (+ (get total-earned owner-profile) total-cost)
      })
    )
    
    (var-set record-counter record-id)
    (var-set total-transactions (+ (var-get total-transactions) u1))
    
    (ok record-id)
  )
)

;; Return a borrowed resource
(define-public (return-resource (record-id uint))
  (let
    (
      (record (unwrap! (map-get? borrowing-records { record-id: record-id }) ERR_NOT_FOUND))
      (resource (unwrap! (map-get? resources { resource-id: (get resource-id record) }) ERR_NOT_FOUND))
    )
    ;; Input validation
    (asserts! (is-valid-record-id record-id) ERR_INVALID_INPUT)
    (asserts! (is-eq tx-sender (get borrower record)) ERR_NOT_BORROWER)
    (asserts! (not (get returned record)) ERR_ALREADY_BORROWED)
    
    ;; Mark as returned
    (map-set borrowing-records
      { record-id: record-id }
      (merge record { returned: true })
    )
    
    ;; Make resource available again
    (map-set resources
      { resource-id: (get resource-id record) }
      (merge resource { available: true })
    )
    
    (ok true)
  )
)

;; Rate a resource after borrowing
(define-public (rate-resource (record-id uint) (rating uint) (comment (string-ascii 200)))
  (let
    (
      (record (unwrap! (map-get? borrowing-records { record-id: record-id }) ERR_NOT_FOUND))
      (rating-id (+ (var-get rating-counter) u1))
    )
    ;; Input validation
    (asserts! (is-valid-record-id record-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-rating rating) ERR_INVALID_RATING)
    (asserts! (is-valid-comment comment) ERR_INVALID_INPUT)
    (asserts! (is-eq tx-sender (get borrower record)) ERR_NOT_BORROWER)
    (asserts! (get returned record) ERR_NOT_AVAILABLE)
    (asserts! (not (get rating-given record)) ERR_ALREADY_BORROWED)
    
    ;; Store rating
    (map-set resource-ratings
      { rating-id: rating-id }
      {
        resource-id: (get resource-id record),
        borrower: tx-sender,
        rating: rating,
        comment: comment,
        timestamp: stacks-block-height
      }
    )
    
    ;; Mark rating as given
    (map-set borrowing-records
      { record-id: record-id }
      (merge record { rating-given: true })
    )
    
    (var-set rating-counter rating-id)
    (ok rating-id)
  )
)

;; Update user profile
(define-public (update-profile (name (string-ascii 50)))
  (let
    (
      (current-profile (default-to 
        { name: "", reputation-score: u100, total-lends: u0, total-borrows: u0, total-earned: u0, total-spent: u0, verified: false }
        (map-get? user-profiles { user: tx-sender })
      ))
    )
    ;; Input validation
    (asserts! (is-valid-profile-name name) ERR_INVALID_INPUT)
    
    (map-set user-profiles
      { user: tx-sender }
      (merge current-profile { name: name })
    )
    (ok true)
  )
)

;; Verify user (admin only)
(define-public (verify-user (user principal))
  (let
    (
      (user-profile (default-to 
        { name: "", reputation-score: u100, total-lends: u0, total-borrows: u0, total-earned: u0, total-spent: u0, verified: false }
        (map-get? user-profiles { user: user })
      ))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set user-profiles
      { user: user }
      (merge user-profile { verified: true, reputation-score: (+ (get reputation-score user-profile) u50) })
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-resource (resource-id uint))
  (map-get? resources { resource-id: resource-id })
)

(define-read-only (get-borrowing-record (record-id uint))
  (map-get? borrowing-records { record-id: record-id })
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-resource-rating (rating-id uint))
  (map-get? resource-ratings { rating-id: rating-id })
)

(define-read-only (get-platform-stats)
  {
    total-resources: (var-get resource-counter),
    total-transactions: (var-get total-transactions),
    total-ratings: (var-get rating-counter),
    total-records: (var-get record-counter)
  }
)

(define-read-only (is-resource-available (resource-id uint))
  (match (map-get? resources { resource-id: resource-id })
    resource (get available resource)
    false
  )
)

(define-read-only (is-borrowing-overdue (record-id uint))
  (match (map-get? borrowing-records { record-id: record-id })
    record (and 
      (not (get returned record))
      (> stacks-block-height (get end-block record))
    )
    false
  )
)

;; Campus Noticeboard Contract
;; Decentralized notice posting system with immutable history

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-not-moderator (err u105))
(define-constant err-already-liked (err u106))
(define-constant err-already-pinned (err u107))
(define-constant max-pinned-notices u10)

;; Data Variables
(define-data-var notice-nonce uint u0)
(define-data-var comment-nonce uint u0)
(define-data-var pinned-count uint u0)
(define-data-var paused bool false)

;; Data Maps
(define-map notices
  uint
  {
    author: principal,
    title: (string-ascii 100),
    content: (string-ascii 500),
    category: (string-ascii 50),
    timestamp: uint,
    active: bool,
    pinned: bool,
    like-count: uint,
    comment-count: uint
  }
)

(define-map user-notice-count principal uint)

(define-map comments
  uint
  {
    notice-id: uint,
    author: principal,
    content: (string-ascii 300),
    timestamp: uint,
    active: bool
  }
)

(define-map notice-likes
  { notice-id: uint, user: principal }
  bool
)

(define-map moderators
  principal
  bool
)

(define-map categories
  (string-ascii 50)
  {
    description: (string-ascii 200),
    notice-count: uint,
    active: bool
  }
)

(define-map user-activity
  principal
  {
    total-notices: uint,
    total-comments: uint,
    total-likes: uint,
    reputation: uint
  }
)

;; Read-only functions
(define-read-only (get-notice (notice-id uint))
  (map-get? notices notice-id)
)

(define-read-only (get-user-notice-count (user principal))
  (default-to u0 (map-get? user-notice-count user))
)

(define-read-only (get-notice-nonce)
  (var-get notice-nonce)
)

(define-read-only (get-comment (comment-id uint))
  (map-get? comments comment-id)
)

(define-read-only (get-comment-nonce)
  (var-get comment-nonce)
)

(define-read-only (has-liked (notice-id uint) (user principal))
  (default-to false (map-get? notice-likes { notice-id: notice-id, user: user }))
)

(define-read-only (is-moderator (user principal))
  (default-to false (map-get? moderators user))
)

(define-read-only (get-category (category-name (string-ascii 50)))
  (map-get? categories category-name)
)

(define-read-only (get-user-activity (user principal))
  (map-get? user-activity user)
)

(define-read-only (get-pinned-count)
  (var-get pinned-count)
)

(define-read-only (is-paused)
  (var-get paused)
)

(define-read-only (is-notice-pinned (notice-id uint))
  (match (map-get? notices notice-id)
    notice (get pinned notice)
    false
  )
)

(define-read-only (get-notice-like-count (notice-id uint))
  (match (map-get? notices notice-id)
    notice (get like-count notice)
    u0
  )
)

;; Public functions
(define-public (post-notice (title (string-ascii 100)) (content (string-ascii 500)) (category (string-ascii 50)))
  (let
    (
      (notice-id (var-get notice-nonce))
      (sender tx-sender)
    )
    (asserts! (not (var-get paused)) err-unauthorized)
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len content) u0) err-invalid-input)
    
    (map-set notices notice-id
      {
        author: sender,
        title: title,
        content: content,
        category: category,
        timestamp: stacks-block-height,
        active: true,
        pinned: false,
        like-count: u0,
        comment-count: u0
      }
    )
    (map-set user-notice-count sender (+ (get-user-notice-count sender) u1))
    
    ;; Update category count
    (match (map-get? categories category)
      cat-info (map-set categories category 
        (merge cat-info { notice-count: (+ (get notice-count cat-info) u1) }))
      (map-set categories category { description: "", notice-count: u1, active: true })
    )
    
    ;; Update user activity
    (update-user-activity-notices sender)
    
    (var-set notice-nonce (+ notice-id u1))
    (ok notice-id)
  )
)

(define-public (deactivate-notice (notice-id uint))
  (let
    (
      (notice (unwrap! (map-get? notices notice-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get author notice)) err-unauthorized)
    (map-set notices notice-id (merge notice { active: false }))
    (ok true)
  )
)

(define-public (post-comment (notice-id uint) (content (string-ascii 300)))
  (let
    (
      (comment-id (var-get comment-nonce))
      (sender tx-sender)
      (notice (unwrap! (map-get? notices notice-id) err-not-found))
    )
    (asserts! (not (var-get paused)) err-unauthorized)
    (asserts! (get active notice) err-not-found)
    (asserts! (> (len content) u0) err-invalid-input)
    
    (map-set comments comment-id
      {
        notice-id: notice-id,
        author: sender,
        content: content,
        timestamp: stacks-block-height,
        active: true
      }
    )
    
    ;; Update notice comment count
    (map-set notices notice-id 
      (merge notice { comment-count: (+ (get comment-count notice) u1) }))
    
    ;; Update user activity
    (update-user-activity-comments sender)
    
    (var-set comment-nonce (+ comment-id u1))
    (ok comment-id)
  )
)

(define-public (like-notice (notice-id uint))
  (let
    (
      (sender tx-sender)
      (notice (unwrap! (map-get? notices notice-id) err-not-found))
    )
    (asserts! (get active notice) err-not-found)
    (asserts! (not (has-liked notice-id sender)) err-already-liked)
    
    (map-set notice-likes { notice-id: notice-id, user: sender } true)
    
    ;; Update notice like count
    (map-set notices notice-id 
      (merge notice { like-count: (+ (get like-count notice) u1) }))
    
    ;; Update user activity
    (update-user-activity-likes sender)
    
    (ok true)
  )
)

(define-public (unlike-notice (notice-id uint))
  (let
    (
      (sender tx-sender)
      (notice (unwrap! (map-get? notices notice-id) err-not-found))
    )
    (asserts! (has-liked notice-id sender) err-not-found)
    
    (map-delete notice-likes { notice-id: notice-id, user: sender })
    
    ;; Update notice like count
    (map-set notices notice-id 
      (merge notice { like-count: (- (get like-count notice) u1) }))
    
    (ok true)
  )
)

(define-public (delete-comment (comment-id uint))
  (let
    (
      (comment (unwrap! (map-get? comments comment-id) err-not-found))
    )
    (asserts! (or 
      (is-eq tx-sender (get author comment))
      (is-eq tx-sender contract-owner)
      (is-moderator tx-sender)
    ) err-unauthorized)
    
    (map-set comments comment-id (merge comment { active: false }))
    (ok true)
  )
)
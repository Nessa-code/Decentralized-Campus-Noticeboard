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
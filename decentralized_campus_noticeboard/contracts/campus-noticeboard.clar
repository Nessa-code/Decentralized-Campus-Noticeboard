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
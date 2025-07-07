;; Proxy Management Contract
;; Handles delegation of voting rights between shareholders

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_DELEGATION (err u201))
(define-constant ERR_ALREADY_DELEGATED (err u202))
(define-constant ERR_NO_DELEGATION (err u203))
(define-constant ERR_SELF_DELEGATION (err u204))

;; Data Variables
(define-data-var total-delegations uint u0)

;; Data Maps
(define-map proxy-delegations principal principal)
(define-map delegation-details principal {
    delegated-to: principal,
    delegated-at: uint,
    active: bool
})
(define-map proxy-holders principal (list 100 principal))

;; Public Functions

;; Delegate voting rights to another principal
(define-public (delegate-voting-rights (proxy principal))
    (begin
        (asserts! (not (is-eq tx-sender proxy)) ERR_SELF_DELEGATION)
        (asserts! (is-none (map-get? proxy-delegations tx-sender)) ERR_ALREADY_DELEGATED)
        (map-set proxy-delegations tx-sender proxy)
        (map-set delegation-details tx-sender {
            delegated-to: proxy,
            delegated-at: block-height,
            active: true
        })
        (let ((current-list (default-to (list) (map-get? proxy-holders proxy))))
            (map-set proxy-holders proxy (unwrap-panic (as-max-len? (append current-list tx-sender) u100)))
        )
        (var-set total-delegations (+ (var-get total-delegations) u1))
        (ok true)
    )
)

;; Revoke delegation
(define-public (revoke-delegation)
    (let ((delegation (map-get? proxy-delegations tx-sender)))
        (asserts! (is-some delegation) ERR_NO_DELEGATION)
        (let ((proxy (unwrap-panic delegation)))
            (map-delete proxy-delegations tx-sender)
            (map-set delegation-details tx-sender (merge
                (unwrap-panic (map-get? delegation-details tx-sender))
                { active: false }
            ))
            (let ((current-list (default-to (list) (map-get? proxy-holders proxy))))
                (map-set proxy-holders proxy (filter is-not-sender current-list))
            )
            (var-set total-delegations (- (var-get total-delegations) u1))
            (ok true)
        )
    )
)

;; Private Functions
(define-private (is-not-sender (principal-to-check principal))
    (not (is-eq principal-to-check tx-sender))
)

;; Read-only Functions

;; Get proxy for a principal
(define-read-only (get-proxy (delegator principal))
    (map-get? proxy-delegations delegator)
)

;; Get delegation details
(define-read-only (get-delegation-details (delegator principal))
    (map-get? delegation-details delegator)
)

;; Get list of principals who delegated to a proxy
(define-read-only (get-delegators (proxy principal))
    (map-get? proxy-holders proxy)
)

;; Check if principal has delegated
(define-read-only (has-delegated (delegator principal))
    (is-some (map-get? proxy-delegations delegator))
)

;; Get total delegations count
(define-read-only (get-total-delegations)
    (var-get total-delegations)
)

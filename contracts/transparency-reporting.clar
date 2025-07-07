;; Transparency Reporting Contract
;; Provides comprehensive audit trails and transparency reports

;; Constants
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_REPORT_NOT_FOUND (err u501))
(define-constant ERR_INVALID_TIMEFRAME (err u502))

;; Data Variables
(define-data-var report-counter uint u0)
(define-data-var public-reporting-enabled bool true)

;; Data Maps
(define-map audit-reports uint {
    report-type: (string-ascii 50),
    proposal-id: uint,
    generated-at: uint,
    generated-by: principal,
    summary: (string-ascii 200),
    public: bool
})

(define-map voting-activities uint {
    activity-type: (string-ascii 30),
    principal-involved: principal,
    proposal-id: uint,
    timestamp: uint,
    details: (string-ascii 100)
})

(define-map transparency-metrics uint {
    total-proposals: uint,
    total-votes: uint,
    average-participation: uint,
    total-participants: uint,
    reporting-period: uint
})

;; Public Functions

;; Generate audit report
(define-public (generate-audit-report (report-type (string-ascii 50)) (proposal-id uint) (summary (string-ascii 200)) (is-public bool))
    (let ((report-id (+ (var-get report-counter) u1)))
        (map-set audit-reports report-id {
            report-type: report-type,
            proposal-id: proposal-id,
            generated-at: block-height,
            generated-by: tx-sender,
            summary: summary,
            public: is-public
        })
        (var-set report-counter report-id)
        (ok report-id)
    )
)

;; Log voting activity
(define-public (log-activity (activity-type (string-ascii 30)) (principal-involved principal) (proposal-id uint) (details (string-ascii 100)))
    (let ((activity-id (+ (var-get report-counter) u1)))
        (map-set voting-activities activity-id {
            activity-type: activity-type,
            principal-involved: principal-involved,
            proposal-id: proposal-id,
            timestamp: block-height,
            details: details
        })
        (ok activity-id)
    )
)

;; Update transparency metrics
(define-public (update-metrics (total-proposals uint) (total-votes uint) (avg-participation uint) (total-participants uint))
    (let ((metrics-id (+ (var-get report-counter) u1)))
        (map-set transparency-metrics metrics-id {
            total-proposals: total-proposals,
            total-votes: total-votes,
            average-participation: avg-participation,
            total-participants: total-participants,
            reporting-period: block-height
        })
        (ok metrics-id)
    )
)

;; Toggle public reporting
(define-public (toggle-public-reporting)
    (begin
        (var-set public-reporting-enabled (not (var-get public-reporting-enabled)))
        (ok (var-get public-reporting-enabled))
    )
)

;; Read-only Functions

;; Get audit report
(define-read-only (get-audit-report (report-id uint))
    (map-get? audit-reports report-id)
)

;; Get voting activity
(define-read-only (get-activity (activity-id uint))
    (map-get? voting-activities activity-id)
)

;; Get transparency metrics
(define-read-only (get-metrics (metrics-id uint))
    (map-get? transparency-metrics metrics-id)
)

;; Check if public reporting is enabled
(define-read-only (is-public-reporting-enabled)
    (var-get public-reporting-enabled)
)

;; Get total reports generated
(define-read-only (get-total-reports)
    (var-get report-counter)
)

;; Get public reports only
(define-read-only (is-report-public (report-id uint))
    (match (map-get? audit-reports report-id)
        report (get public report)
        false
    )
)

;; Generate transparency summary
(define-read-only (get-transparency-summary (proposal-id uint))
    {
        proposal-id: proposal-id,
        reports-available: true,
        public-access: (var-get public-reporting-enabled),
        last-updated: block-height
    }
)

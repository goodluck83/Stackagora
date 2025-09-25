;; Stackagora - Decentralized Social Network on Stacks
;; A community-driven social platform where users own their content and governance

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-POST-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-USER-NOT-FOUND (err u104))
(define-constant ERR-INVALID-TIP-AMOUNT (err u105))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-TIP-AMOUNT u1000000) ;; 1 STX in microSTX

;; Data variables
(define-data-var next-post-id uint u1)
(define-data-var next-user-id uint u1)
(define-data-var platform-fee-percentage uint u250) ;; 2.5%

;; Data maps
(define-map posts
  { post-id: uint }
  {
    author: principal,
    content: (string-ascii 500),
    timestamp: uint,
    upvotes: uint,
    downvotes: uint,
    tips-received: uint,
    is-active: bool
  }
)

(define-map users
  { user-principal: principal }
  {
    user-id: uint,
    username: (string-ascii 50),
    bio: (string-ascii 200),
    posts-count: uint,
    reputation: uint,
    total-tips-received: uint,
    joined-at: uint
  }
)

(define-map post-votes
  { post-id: uint, voter: principal }
  { vote-type: (string-ascii 10) } ;; "upvote" or "downvote"
)

(define-map post-tips
  { post-id: uint, tipper: principal }
  { amount: uint, timestamp: uint }
)

(define-map user-follows
  { follower: principal, followed: principal }
  { timestamp: uint }
)

;; Read-only functions
(define-read-only (get-post (post-id uint))
  (map-get? posts { post-id: post-id })
)

(define-read-only (get-user (user-principal principal))
  (map-get? users { user-principal: user-principal })
)

(define-read-only (get-post-vote (post-id uint) (voter principal))
  (map-get? post-votes { post-id: post-id, voter: voter })
)

(define-read-only (get-user-reputation (user-principal principal))
  (default-to u0 (get reputation (map-get? users { user-principal: user-principal })))
)

(define-read-only (get-platform-stats)
  {
    total-posts: (- (var-get next-post-id) u1),
    total-users: (- (var-get next-user-id) u1),
    platform-fee: (var-get platform-fee-percentage)
  }
)

(define-read-only (is-following (follower principal) (followed principal))
  (is-some (map-get? user-follows { follower: follower, followed: followed }))
)

;; Public functions

;; Register a new user
(define-public (register-user (username (string-ascii 50)) (bio (string-ascii 200)))
  (let ((user-id (var-get next-user-id)))
    (asserts! (is-none (map-get? users { user-principal: tx-sender })) ERR-NOT-AUTHORIZED)
    (map-set users
      { user-principal: tx-sender }
      {
        user-id: user-id,
        username: username,
        bio: bio,
        posts-count: u0,
        reputation: u100, ;; Starting reputation
        total-tips-received: u0,
        joined-at: block-height
      }
    )
    (var-set next-user-id (+ user-id u1))
    (ok user-id)
  )
)

;; Create a new post
(define-public (create-post (content (string-ascii 500)))
  (let ((post-id (var-get next-post-id))
        (user-data (unwrap! (map-get? users { user-principal: tx-sender }) ERR-USER-NOT-FOUND)))
    (map-set posts
      { post-id: post-id }
      {
        author: tx-sender,
        content: content,
        timestamp: block-height,
        upvotes: u0,
        downvotes: u0,
        tips-received: u0,
        is-active: true
      }
    )
    ;; Update user's post count
    (map-set users
      { user-principal: tx-sender }
      (merge user-data { posts-count: (+ (get posts-count user-data) u1) })
    )
    (var-set next-post-id (+ post-id u1))
    (ok post-id)
  )
)

;; Vote on a post (upvote or downvote)
(define-public (vote-post (post-id uint) (vote-type (string-ascii 10)))
  (let ((post-data (unwrap! (map-get? posts { post-id: post-id }) ERR-POST-NOT-FOUND))
        (existing-vote (map-get? post-votes { post-id: post-id, voter: tx-sender })))
    (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)
    (asserts! (get is-active post-data) ERR-POST-NOT-FOUND)
    (asserts! (or (is-eq vote-type "upvote") (is-eq vote-type "downvote")) ERR-NOT-AUTHORIZED)
    
    ;; Record the vote
    (map-set post-votes
      { post-id: post-id, voter: tx-sender }
      { vote-type: vote-type }
    )
    
    ;; Update post vote counts
    (if (is-eq vote-type "upvote")
      (map-set posts
        { post-id: post-id }
        (merge post-data { upvotes: (+ (get upvotes post-data) u1) })
      )
      (map-set posts
        { post-id: post-id }
        (merge post-data { downvotes: (+ (get downvotes post-data) u1) })
      )
    )
    
    ;; Update author reputation
    (update-author-reputation (get author post-data) vote-type)
    (ok true)
  )
)

;; Tip a post author
(define-public (tip-post (post-id uint) (amount uint))
  (let ((post-data (unwrap! (map-get? posts { post-id: post-id }) ERR-POST-NOT-FOUND))
        (author (get author post-data))
        (platform-fee (/ (* amount (var-get platform-fee-percentage)) u10000))
        (author-amount (- amount platform-fee)))
    (asserts! (>= amount MIN-TIP-AMOUNT) ERR-INVALID-TIP-AMOUNT)
    (asserts! (get is-active post-data) ERR-POST-NOT-FOUND)
    (asserts! (not (is-eq tx-sender author)) ERR-NOT-AUTHORIZED)
    
    ;; Transfer STX to author
    (try! (stx-transfer? author-amount tx-sender author))
    
    ;; Transfer platform fee to contract owner
    (try! (stx-transfer? platform-fee tx-sender CONTRACT-OWNER))
    
    ;; Record the tip
    (map-set post-tips
      { post-id: post-id, tipper: tx-sender }
      { amount: amount, timestamp: block-height }
    )
    
    ;; Update post tips received
    (map-set posts
      { post-id: post-id }
      (merge post-data { tips-received: (+ (get tips-received post-data) amount) })
    )
    
    ;; Update author's total tips received
    (let ((author-data (unwrap! (map-get? users { user-principal: author }) ERR-USER-NOT-FOUND)))
      (map-set users
        { user-principal: author }
        (merge author-data { 
          total-tips-received: (+ (get total-tips-received author-data) amount),
          reputation: (+ (get reputation author-data) u10) ;; Bonus reputation for receiving tips
        })
      )
    )
    (ok true)
  )
)

;; Follow a user
(define-public (follow-user (user-to-follow principal))
  (begin
    (asserts! (not (is-eq tx-sender user-to-follow)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? users { user-principal: user-to-follow })) ERR-USER-NOT-FOUND)
    (map-set user-follows
      { follower: tx-sender, followed: user-to-follow }
      { timestamp: block-height }
    )
    (ok true)
  )
)

;; Unfollow a user
(define-public (unfollow-user (user-to-unfollow principal))
  (begin
    (asserts! (is-some (map-get? user-follows { follower: tx-sender, followed: user-to-unfollow })) ERR-USER-NOT-FOUND)
    (map-delete user-follows { follower: tx-sender, followed: user-to-unfollow })
    (ok true)
  )
)

;; Moderate content (only contract owner)
(define-public (moderate-post (post-id uint) (is-active bool))
  (let ((post-data (unwrap! (map-get? posts { post-id: post-id }) ERR-POST-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set posts
      { post-id: post-id }
      (merge post-data { is-active: is-active })
    )
    (ok true)
  )
)

;; Update platform fee (only contract owner)
(define-public (update-platform-fee (new-fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-percentage u1000) ERR-NOT-AUTHORIZED) ;; Max 10%
    (var-set platform-fee-percentage new-fee-percentage)
    (ok true)
  )
)

;; Private functions
(define-private (update-author-reputation (author principal) (vote-type (string-ascii 10)))
  (let ((author-data (unwrap-panic (map-get? users { user-principal: author }))))
    (map-set users
      { user-principal: author }
      (merge author-data {
        reputation: (if (is-eq vote-type "upvote")
          (+ (get reputation author-data) u5)
          (if (> (get reputation author-data) u5)
            (- (get reputation author-data) u5)
            u0
          )
        )
      })
    )
  )
)
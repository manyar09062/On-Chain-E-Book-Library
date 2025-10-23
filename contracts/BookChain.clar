;; BookChain - On-Chain E-Book Library Smart Contract

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_BOOK_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_ALREADY_OWNS_BOOK (err u103))
(define-constant ERR_BOOK_ALREADY_EXISTS (err u104))
(define-constant ERR_INVALID_PRICE (err u105))
(define-constant ERR_RENTAL_EXPIRED (err u106))
(define-constant ERR_BOOK_NOT_AVAILABLE (err u107))
(define-constant ERR_GIFT_NOT_FOUND (err u108))
(define-constant ERR_GIFT_ALREADY_CLAIMED (err u109))
(define-constant ERR_NOT_GIFT_RECIPIENT (err u110))

(define-data-var next-book-id uint u1)
(define-data-var platform-fee-percentage uint u5)

(define-map books
  { book-id: uint }
  {
    title: (string-ascii 100),
    author: principal,
    price: uint,
    rental-price: uint,
    total-copies: uint,
    available-copies: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map book-owners
  { book-id: uint, owner: principal }
  { purchased-at: uint, access-type: (string-ascii 10) }
)

(define-map book-rentals
  { book-id: uint, renter: principal }
  { rented-at: uint, expires-at: uint }
)

(define-map author-earnings
  { author: principal }
  { total-earned: uint }
)

(define-map user-library
  { user: principal }
  { books-owned: (list 1000 uint), books-rented: (list 100 uint) }
)

(define-data-var next-gift-id uint u1)

(define-map book-gifts
  { gift-id: uint }
  {
    book-id: uint,
    sender: principal,
    recipient: principal,
    message: (string-utf8 200),
    gifted-at: uint,
    claimed: bool,
    claimed-at: (optional uint)
  }
)

(define-map user-gifts-sent
  { user: principal }
  { gift-ids: (list 100 uint) }
)

(define-map user-gifts-received
  { user: principal }
  { gift-ids: (list 100 uint) }
)

(define-public (add-book (title (string-ascii 100)) (price uint) (rental-price uint) (total-copies uint))
  (let
    (
      (book-id (var-get next-book-id))
      (current-block burn-block-height)
    )
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (> total-copies u0) ERR_INVALID_PRICE)
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    (map-set books
      { book-id: book-id }
      {
        title: title,
        author: tx-sender,
        price: price,
        rental-price: rental-price,
        total-copies: total-copies,
        available-copies: total-copies,
        created-at: current-block,
        is-active: true
      }
    )
    
    (var-set next-book-id (+ book-id u1))
    (ok book-id)
  )
)

(define-public (purchase-book (book-id uint))
  (let
    (
      (book (unwrap! (map-get? books { book-id: book-id }) ERR_BOOK_NOT_FOUND))
      (buyer tx-sender)
      (author (get author book))
      (book-price (get price book))
      (platform-fee (/ (* book-price (var-get platform-fee-percentage)) u100))
      (author-payment (- book-price platform-fee))
      (current-block burn-block-height)
    )
    (asserts! (get is-active book) ERR_BOOK_NOT_AVAILABLE)
    (asserts! (> (get available-copies book) u0) ERR_BOOK_NOT_AVAILABLE)
    (asserts! (is-none (map-get? book-owners { book-id: book-id, owner: buyer })) ERR_ALREADY_OWNS_BOOK)
    
    (try! (stx-transfer? book-price buyer CONTRACT_OWNER))
    (try! (stx-transfer? author-payment CONTRACT_OWNER author))
    
    (map-set books
      { book-id: book-id }
      (merge book { available-copies: (- (get available-copies book) u1) })
    )
    
    (map-set book-owners
      { book-id: book-id, owner: buyer }
      { purchased-at: current-block, access-type: "purchase" }
    )
    
    (unwrap-panic (update-author-earnings author author-payment))
    (unwrap-panic (add-to-user-library buyer book-id "owned"))
    
    (ok true)
  )
)

(define-public (rent-book (book-id uint) (rental-days uint))
  (let
    (
      (book (unwrap! (map-get? books { book-id: book-id }) ERR_BOOK_NOT_FOUND))
      (renter tx-sender)
      (author (get author book))
      (rental-price (* (get rental-price book) rental-days))
      (platform-fee (/ (* rental-price (var-get platform-fee-percentage)) u100))
      (author-payment (- rental-price platform-fee))
      (current-block burn-block-height)
      (expires-at (+ current-block (* rental-days u144)))
    )
    (asserts! (get is-active book) ERR_BOOK_NOT_AVAILABLE)
    (asserts! (> rental-days u0) ERR_INVALID_PRICE)
    (asserts! (<= rental-days u30) ERR_INVALID_PRICE)
    
    (try! (stx-transfer? rental-price renter CONTRACT_OWNER))
    (try! (stx-transfer? author-payment CONTRACT_OWNER author))
    
    (map-set book-rentals
      { book-id: book-id, renter: renter }
      { rented-at: current-block, expires-at: expires-at }
    )
    
    (unwrap-panic (update-author-earnings author author-payment))
    (unwrap-panic (add-to-user-library renter book-id "rented"))
    
    (ok expires-at)
  )
)

(define-public (update-book-status (book-id uint) (is-active bool))
  (let
    (
      (book (unwrap! (map-get? books { book-id: book-id }) ERR_BOOK_NOT_FOUND))
      (author (get author book))
    )
    (asserts! (is-eq tx-sender author) ERR_NOT_AUTHORIZED)
    
    (map-set books
      { book-id: book-id }
      (merge book { is-active: is-active })
    )
    
    (ok true)
  )
)

(define-public (update-book-price (book-id uint) (new-price uint) (new-rental-price uint))
  (let
    (
      (book (unwrap! (map-get? books { book-id: book-id }) ERR_BOOK_NOT_FOUND))
      (author (get author book))
    )
    (asserts! (is-eq tx-sender author) ERR_NOT_AUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_PRICE)
    
    (map-set books
      { book-id: book-id }
      (merge book { price: new-price, rental-price: new-rental-price })
    )
    
    (ok true)
  )
)

(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee u20) ERR_INVALID_PRICE)
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

(define-public (gift-book (book-id uint) (recipient principal) (message (string-utf8 200)))
  (let
    (
      (book (unwrap! (map-get? books { book-id: book-id }) ERR_BOOK_NOT_FOUND))
      (sender tx-sender)
      (author (get author book))
      (book-price (get price book))
      (platform-fee (/ (* book-price (var-get platform-fee-percentage)) u100))
      (author-payment (- book-price platform-fee))
      (current-block burn-block-height)
      (gift-id (var-get next-gift-id))
    )
    (asserts! (get is-active book) ERR_BOOK_NOT_AVAILABLE)
    (asserts! (> (get available-copies book) u0) ERR_BOOK_NOT_AVAILABLE)
    (asserts! (not (is-eq sender recipient)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? book-owners { book-id: book-id, owner: recipient })) ERR_ALREADY_OWNS_BOOK)
    
    (try! (stx-transfer? book-price sender CONTRACT_OWNER))
    (try! (stx-transfer? author-payment CONTRACT_OWNER author))
    
    (map-set books
      { book-id: book-id }
      (merge book { available-copies: (- (get available-copies book) u1) })
    )
    
    (map-set book-gifts
      { gift-id: gift-id }
      {
        book-id: book-id,
        sender: sender,
        recipient: recipient,
        message: message,
        gifted-at: current-block,
        claimed: false,
        claimed-at: none
      }
    )
    
    (unwrap-panic (update-author-earnings author author-payment))
    (unwrap-panic (track-gift-sent sender gift-id))
    (unwrap-panic (track-gift-received recipient gift-id))
    
    (var-set next-gift-id (+ gift-id u1))
    (ok gift-id)
  )
)

(define-public (claim-gift (gift-id uint))
  (let
    (
      (gift (unwrap! (map-get? book-gifts { gift-id: gift-id }) ERR_GIFT_NOT_FOUND))
      (claimer tx-sender)
      (book-id (get book-id gift))
      (recipient (get recipient gift))
      (current-block burn-block-height)
    )
    (asserts! (is-eq claimer recipient) ERR_NOT_GIFT_RECIPIENT)
    (asserts! (not (get claimed gift)) ERR_GIFT_ALREADY_CLAIMED)
    (asserts! (is-none (map-get? book-owners { book-id: book-id, owner: claimer })) ERR_ALREADY_OWNS_BOOK)
    
    (map-set book-owners
      { book-id: book-id, owner: claimer }
      { purchased-at: current-block, access-type: "gift" }
    )
    
    (map-set book-gifts
      { gift-id: gift-id }
      (merge gift { claimed: true, claimed-at: (some current-block) })
    )
    
    (unwrap-panic (add-to-user-library claimer book-id "owned"))
    
    (ok true)
  )
)

(define-public (withdraw-earnings)
  (let
    (
      (earnings (default-to { total-earned: u0 } (map-get? author-earnings { author: tx-sender })))
      (amount (get total-earned earnings))
    )
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    
    (try! (stx-transfer? amount CONTRACT_OWNER tx-sender))
    
    (map-set author-earnings
      { author: tx-sender }
      { total-earned: u0 }
    )
    
    (ok amount)
  )
)

(define-private (update-author-earnings (author principal) (amount uint))
  (let
    (
      (current-earnings (default-to { total-earned: u0 } (map-get? author-earnings { author: author })))
    )
    (map-set author-earnings
      { author: author }
      { total-earned: (+ (get total-earned current-earnings) amount) }
    )
    (ok true)
  )
)

(define-private (track-gift-sent (sender principal) (gift-id uint))
  (let
    (
      (current-gifts (default-to { gift-ids: (list) } (map-get? user-gifts-sent { user: sender })))
    )
    (map-set user-gifts-sent
      { user: sender }
      { gift-ids: (unwrap! (as-max-len? (append (get gift-ids current-gifts) gift-id) u100) (err u999)) }
    )
    (ok true)
  )
)

(define-private (track-gift-received (recipient principal) (gift-id uint))
  (let
    (
      (current-gifts (default-to { gift-ids: (list) } (map-get? user-gifts-received { user: recipient })))
    )
    (map-set user-gifts-received
      { user: recipient }
      { gift-ids: (unwrap! (as-max-len? (append (get gift-ids current-gifts) gift-id) u100) (err u999)) }
    )
    (ok true)
  )
)

(define-private (add-to-user-library (user principal) (book-id uint) (access-type (string-ascii 10)))
  (let
    (
      (current-library (default-to { books-owned: (list), books-rented: (list) } (map-get? user-library { user: user })))
    )
    (if (is-eq access-type "owned")
      (map-set user-library
        { user: user }
        (merge current-library { books-owned: (unwrap! (as-max-len? (append (get books-owned current-library) book-id) u1000) (err u999)) })
      )
      (map-set user-library
        { user: user }
        (merge current-library { books-rented: (unwrap! (as-max-len? (append (get books-rented current-library) book-id) u100) (err u999)) })
      )
    )
    (ok true)
  )
)

(define-read-only (get-book (book-id uint))
  (map-get? books { book-id: book-id })
)

(define-read-only (get-book-count)
  (- (var-get next-book-id) u1)
)

(define-read-only (has-access (book-id uint) (user principal))
  (let
    (
      (ownership (map-get? book-owners { book-id: book-id, owner: user }))
      (rental (map-get? book-rentals { book-id: book-id, renter: user }))
      (current-block burn-block-height)
    )
    (or
      (is-some ownership)
      (match rental
        rental-data (> (get expires-at rental-data) current-block)
        false
      )
    )
  )
)

(define-read-only (get-rental-status (book-id uint) (user principal))
  (let
    (
      (rental (map-get? book-rentals { book-id: book-id, renter: user }))
      (current-block burn-block-height)
    )
    (match rental
      rental-data 
      (if (> (get expires-at rental-data) current-block)
        (some { expires-at: (get expires-at rental-data), blocks-remaining: (- (get expires-at rental-data) current-block) })
        none
      )
      none
    )
  )
)

(define-read-only (get-author-earnings (author principal))
  (map-get? author-earnings { author: author })
)

(define-read-only (get-user-library (user principal))
  (map-get? user-library { user: user })
)

(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

(define-read-only (is-book-available (book-id uint))
  (match (map-get? books { book-id: book-id })
    book (and (get is-active book) (> (get available-copies book) u0))
    false
  )
)

(define-read-only (get-book-ownership (book-id uint) (user principal))
  (map-get? book-owners { book-id: book-id, owner: user })
)

(define-read-only (calculate-rental-cost (book-id uint) (rental-days uint))
  (match (map-get? books { book-id: book-id })
    book
    (let
      (
        (rental-price (* (get rental-price book) rental-days))
        (platform-fee (/ (* rental-price (var-get platform-fee-percentage)) u100))
      )
      (some { total-cost: rental-price, platform-fee: platform-fee, author-payment: (- rental-price platform-fee) })
    )
    none
  )
)

(define-read-only (get-gift (gift-id uint))
  (map-get? book-gifts { gift-id: gift-id })
)

(define-read-only (get-gifts-sent (user principal))
  (map-get? user-gifts-sent { user: user })
)

(define-read-only (get-gifts-received (user principal))
  (map-get? user-gifts-received { user: user })
)

(define-read-only (get-unclaimed-gifts (user principal))
  (let
    (
      (received-gifts (default-to { gift-ids: (list) } (map-get? user-gifts-received { user: user })))
    )
    (filter is-gift-unclaimed (get gift-ids received-gifts))
  )
)

(define-private (is-gift-unclaimed (gift-id uint))
  (match (map-get? book-gifts { gift-id: gift-id })
    gift (not (get claimed gift))
    false
  )
)

(define-read-only (get-gift-count)
  (- (var-get next-gift-id) u1)
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)



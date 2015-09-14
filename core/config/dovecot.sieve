plugin {
    sieve_before = /vmail/sieve/spam-global.sieve
    sieve = /vmail/%d/%n/sieve/scripts/active.sieve
    sieve_extensions = +fileinto +imapflags +regex +copy
}

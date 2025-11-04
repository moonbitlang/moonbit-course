// crypto.mbt - Cryptographic utilities using SHA-256

///|
/// Compute SHA-256 hash of a string
fn hash_content(content : String) -> String {
  let digest = @sha256.Digest::new()
  let bytes = @encoding/utf8.encode(content)
  for b in bytes {
    digest.write(b)
  }
  digest.check_sum()
}

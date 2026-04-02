#![forbid(unsafe_code)]
#![warn(clippy::all, clippy::pedantic)]

/// Returns the stable identifier for the search crate.
#[must_use]
pub const fn crate_name() -> &'static str {
    "youaskm3-search"
}

#[cfg(test)]
mod tests {
    use super::crate_name;

    #[test]
    fn crate_name_matches_package() {
        assert_eq!(crate_name(), "youaskm3-search");
    }
}

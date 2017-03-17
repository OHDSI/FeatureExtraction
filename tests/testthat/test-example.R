#
#

test_that("example", {
    ch <- sprintf("hello this is test")
    expect_that(ch, is_equivalent_to("hello this is a test"))
  }
)
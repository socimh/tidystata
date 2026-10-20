# set_seed() reports a missing or invalid seed

    Code
      set_seed()
    Condition
      Error in `set_seed()`:
      ! Supply a seed, as in `set_seed(123)`.
    Code
      set_seed("a")
    Condition
      Error in `set_seed()`:
      ! Used alone, `set_seed()` needs one number as the seed, as in `set_seed(123)`.
      i In a pipeline, give the seed: `x %>% set_seed(123)`.


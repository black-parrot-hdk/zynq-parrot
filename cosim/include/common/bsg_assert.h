
#ifndef BSG_ASSERT_H
#define BSG_ASSERT_H

#include <cassert>

#define __bsg_assert1(cond)      assert((cond))
#define __bsg_assert2(cond, msg) assert((cond) && (msg))

#define __get_macro(_1, _2, NAME, ...) NAME

//#define bsg_assert(...) __get_macro(__VA_ARGS__, __bsg_assert2, __bsg_assert1)(__VA_ARGS__)
#define bsg_assert(...) { }

#endif

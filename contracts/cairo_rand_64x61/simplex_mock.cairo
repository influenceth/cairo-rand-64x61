%lang starknet

from cairo_rand_64x61.simplex import Simplex

@view
func Simplex_noise3_test{range_check_ptr}(v: (felt, felt, felt)) -> (res: felt) {
    let res = Simplex.noise3(v);
    return (res = res);
}

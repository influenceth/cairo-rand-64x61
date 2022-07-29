%lang starknet

from Simplex3D import Simplex3D

@view
func Simplex3D_noise_test {range_check_ptr} (v: (felt, felt, felt)) -> (res: felt):
    let (res) = Simplex3D.noise(v)
    return (res)
end

@view
func Simplex3D__mod289_test {range_check_ptr} (x: felt) -> (res: felt):
    let (res) = Simplex3D._mod289(x)
    return (res)
end
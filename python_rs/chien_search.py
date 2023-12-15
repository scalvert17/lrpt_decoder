import galois
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="power")
#GF = galois.GF(2**3, irreducible_poly="x^3 + x + 1", repr="int")  # Testing polynomial


def chien_search(lambda_poly, q=256):
    """
    Inputs:
      lambda_poly: galois.Poly; descending order of x (x^3, x^2, x, 1)

    Outputs:
      error_locs: list; list of GF(2^8) elements, [X_1, X_2, ...]

    Evaluates lambda_poly at alpha^0, alpha^1, ... , alpha^254. The inverse of each
    alpha such that lambda_poly(alpha^i)=0 is an error location. The alpha^-i will be appended
    to error_locs. The error locatins are X_l and the zeros of lambda are X_l^(-1).
    """
    alpha = GF(2)
    error_locs = []

    for i in range(q-1):
        alpha_power = alpha**(11*i)
        if (lambda_poly(alpha_power) == 0):
            with GF.repr('power'):
                print('This is a zero:', alpha_power, '  This is i:', i)
            error_locs.append(alpha ** (-i))

    return error_locs

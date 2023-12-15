import galois
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="power")
#GF = galois.GF(2**3, irreducible_poly="x^3 + x + 1", repr="power")  # Testing polynomial
alpha = GF(2)

def forney(lambda_poly, omega_poly, error_locs):
    """
    Inputs:
      lambda_poly: galois.Poly; descending order of x (x^3, x^2, x, 1)
      omega_poly:  galois.Poly; descending order of x (x^3, x^2, x, 1)
      error_locs:  list; list of GF(2^8) elements representing the error locations X_l
    
    Outputs:
      error_mags:  list; list of GF(2^8) elements representing the error magnitudes
                         at the error_locs locations

    This fucntion performs Forney's algorithm to find the error locations at error locations
    error_locs.
    """
    error_mags = []

    # Create lambda_poly_prime. Derivative of lambda_poly
    lambda_poly_dx = lambda_poly.derivative()

    # For each error location X_l, compute e_l = omega_poly(X_l^(-1)) / (X_l^(-1) * lambda_poly_dx(X_l^(-1)))
    for interm in error_locs:
        """ loc_inv = loc ** (-1)
        num = omega_poly(loc_inv)
        den = loc_inv * lambda_poly_dx(loc_inv)
        error_mags.append(num/den) """

        loc_inv = (interm**11)**(-1)
        loc = loc_inv ** (-1)
        with GF.repr('power'):
            print(loc, loc_inv)
        loc_fcr = loc **(1-112)

        num = loc_fcr * omega_poly(loc_inv)
        den = lambda_poly_dx(loc_inv)
        div = -(num/den)
        error_mags.append(num/den)

        
    
    return error_mags




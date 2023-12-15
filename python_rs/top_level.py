import galois
import copy
GF = galois.GF(2**8, irreducible_poly="x^8 + x^7 + x^2 + x + 1", repr="int")

from syndromes import *
from berlekamp_massey import *
from error_evaluator import *
from chien_search import *
from forney import *
from error_corrector import *

##############################
# top_level module (RIGHT NOW AT LEAST) should take in a 255 length code_word and output
# the 223 length message. I think I'll change all the modules to exclusively handle galois.Poly
# inputs and outputs. That way I can just change the initial and end data types here.


###### TESTING INPUT #####################
code_word_correct =  [255, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 98, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 164, 1, 1, 129, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 123, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 254,
                  45, 71, 110, 154, 239, 158, 216, 74, 48, 159, 222, 171, 65, 21, 130, 154,
                  93, 26, 199, 213, 32, 206, 173, 221, 20, 74, 161, 180, 89, 95, 220]

code_word_dec =  [255, 2, 1, 1, 1, 5, 1, 1, 1, 69, 1, 1, 1, 1, 1, 1, 
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 98, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 164, 1, 1, 129, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 123, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 254,
                  45, 71, 110, 154, 239, 158, 216, 74, 48, 159, 222, 171, 65, 21, 130, 154,
                  93, 26, 199, 213, 32, 206, 173, 221, 20, 74, 161, 180, 89, 95, 220]
##############################


def top_level(code_word_dec):
    # CHANGE THE INPUT TYPE
    init_input = code_word_dec  #assuming the initial input is a 255 length list of ints. Change later. In descending x order
    code_word_elems = [GF(elem) for elem in init_input]
    code_word_poly = galois.Poly(code_word_elems, field=GF)  #Polynomial version of code_word. Proper input of the funcitons

    # SYNDROMES
    syndrome_poly = syndromes_finder(code_word_poly)  #WORKS
    syndrome_coeffs = [int(elem) for elem in syndrome_poly.coefficients()]
    #with GF.repr('int'):
    #    print('syndrome:', syndrome_coeffs)
    syndrome_coeffs.reverse()
    syndrome_rev_field = GF(syndrome_coeffs)

    # BERLEKAMP-MASSEY; LAMBDA
    #lambda_poly_rev = galois.berlekamp_massey(syndrome_rev_field)
    #lambda_poly = galois.Poly.reverse(lambda_poly_rev)
    lambda_poly = berlekamp_massey(syndrome_poly)
    #print(lambda_poly)



    omega_poly = rs_error_evaluator_poly(lambda_poly, syndrome_poly)
    """ with GF.repr('int'):
        print('lambda:', lambda_poly)
        print('syndrome:', syndrome_poly) """

    error_locs_list = chien_search(lambda_poly)
    """ zeros = lambda_poly.roots()
    error_locs_list = [zero**(-1) for zero in zeros] """
    with GF.repr('power'):
        print(f'error_locs_list: {error_locs_list}')

    error_mags = forney(lambda_poly, omega_poly, error_locs_list)
    with GF.repr('power'):
        print(f'error_mags: {error_mags}')

    corr_code_word_poly = error_corrector(code_word_poly, error_locs_list, error_mags)
    return corr_code_word_poly


#Call the function
correct_code_word_poly = top_level(code_word_dec)
correct_code_word_list = [int(elem) for elem in correct_code_word_poly.coefficients()]
with GF.repr('int'):
    print(correct_code_word_list)

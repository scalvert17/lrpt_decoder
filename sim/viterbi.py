# Code was adapted from the following source: 
# https://github.com/marianoesteban/mit602/blob/main/ps3/PS3_viterbi.py

import numpy, sys
import viterbi_utils 

class ViterbiDecoder:
    # Given the constraint length and a list of parity generator
    # functions, do the initial set up for the decoder.  The
    # following useful instance variables are created:
    #   self.K
    #   self.nstates
    #   self.r
    #   self.predecessor_states
    #   self.expected_parity
    def __init__(self, K, glist):
        self.K = K             # constraint length
        self.nstates = 2**(K-1) # number of states in state machine

        # number of parity bits transmitted for each message bit
        self.r = len(glist)     

        # States are named using (K-1)-bit integers in the range 0 to
        # nstates-1. The bit representation of the integer corresponds
        # to state label in the transition diagram.  So state 10 is
        # named with the integer 2, state 00 is named with the
        # integer 0.

        # for each state s, figure out the two states in the diagram
        # that have transitions ending at state s.  Record these two
        # states as a two-element tuple.
        self.predecessor_states = \
          [((2*s+0) % self.nstates,(2*s+1) % self.nstates)
           for s in range(self.nstates)]

        # this is a 2D table implemented as a list of lists.
        # self.expected_parity[s1][s2] returns the r-bit sequence
        # of parity bits the encoder transmitted when make the
        # state transition from s1 to s2.
        self.expected_parity = \
          [[viterbi_utils.expected_parity(s1, s2, K, glist) \
            if s1 in self.predecessor_states[s2] else None
            for s2 in range(self.nstates)]
           for s1 in range(self.nstates)]

    # expected is an r-element list of the expected parity bits.
    # received is an r-element list of actual sampled voltages for the
    # incoming parity bits.  This is a hard-decision branch metric,
    # so, as described in lab write up, digitize the received voltages
    # to get bits and then compute the Hamming distance between the
    # expected sequence and the received sequence, return that as the
    # Euclidian distance
    def branch_metric(self,expected,received):
        bm = 0.0
        for i in range(self.r):
            bm += (expected[i] - received[i])**2
        return bm

    # Compute self.PM[...,n] from the batch of r parity bits and the
    # path metrics for self.PM[...,n-1] computed on the previous
    # iteration.  Consult the method described in the lab write up.
    # In addition to making an entry for self.PM[s,n] for each state
    # s, keep track of the most-likely predecessor for each state in
    # the self.Predecessor array (a two-dimensional array indexed by s
    # and n).  You'll probably find the following instance variables
    # and methods useful: self.predecessor_states, self.expected_parity,
    # and self.branch_metric().  To see what these mean, scan through the
    # code above.
    def viterbi_step(self,n,received_voltages):
        for i in range(self.nstates):
            a, b = self.predecessor_states[i] # a and b are the two predecessor
                                              # states of i
            # path metric from a
            pm_a = self.PM[a,n-1] + self.branch_metric(self.expected_parity[a][i], received_voltages)
            # path metric from b
            pm_b = self.PM[b,n-1] + self.branch_metric(self.expected_parity[b][i], received_voltages)
            if pm_a.item() < pm_b.item():
                self.PM[i,n] = pm_a.item()
                self.Predecessor[i][n] = a
            else:
                self.PM[i,n] = pm_b.item()
                self.Predecessor[i][n] = b

    # Identify the most-likely ending state of the encoder by
    # finding the state s that has the minimum value of PM[s,n]
    # where n points to the last column of the trellis.  If there
    # are several states with the same minimum value, choose one
    # arbitrarily.  Return the state s.
    def most_likely_state(self,n):
        min_pm = 1000000
        for s in range(self.nstates):
            if self.PM[s,n] < min_pm:
                min_pm = self.PM[s,n]
                min_s = s
        return min_s

    # Starting at state s at time n, use the Predecessor
    # array to find all the states on the most-likely
    # path (in reverse order since we're tracing back through
    # the trellis).  Each state contributes a message bit.
    # Return the decoded message as a sequence of 0's and 1's.
    def traceback(self,s,n):
        message = []
        current_state = s
        for i in reversed(range(n)):
            predecessor_state = self.Predecessor[current_state][i+1]
            message_bit = 0
            if current_state >= predecessor_state and current_state != 0:
                message_bit = 1
            message.insert(0, message_bit) # insert at the front
            current_state = predecessor_state
        return message

    # Figure out what the transmitter sent from info in the
    # received voltages.
    def decode(self,received_voltages,debug=False):
        # figure out how many columns are in the trellis
        nreceived = len(received_voltages)
        max_n = (nreceived/self.r) + 1

        # this is the path metric trellis itself, organized as a
        # 2D array: rows are the states, columns are the time points.
        # PM[s,n] is the metric for the most-likely path through the
        # trellis arriving at state s at time n.
        self.PM = numpy.zeros((int(self.nstates),int(max_n)))

        # at time 0, the starting state is the most likely, the other
        # states are "infinitely" worse.
        self.PM[1:self.nstates,0] = 1000000

        # a 2D array: rows are the states, columns are the time
        # points, contents indicate the predecessor state for each
        # current state.
        self.Predecessor = numpy.zeros((int(self.nstates),int(max_n)))

        # use the Viterbi algorithm to compute PM
        # incrementally from the received parity bits.
        n = 0
        for i in range(0,nreceived,self.r):
            n += 1

            # Fill in the next columns of PM, Predecessor based
            # on info in the next r incoming parity bits
            self.viterbi_step(n,received_voltages[i:i+self.r])

            # print out what was just added to the trellis state

        # if debug:
        #      print "Final PM table \n"
        #      for curState in range(0,self.nstates) :
        #         for time in range(len(self.PM[curState,:])) :
        #             if((self.PM[curState,time])>=1000000) :
        #                 print 'inf ',
        #             else :
        #                 print '%3d ' % (self.PM[curState,time]) ,              # print all times for a given state as one row 
        #         print '\n'
        #      print "\n Final Predecessor table \n"
        #      for curState in range(0,self.nstates) :
        #         for time in range(len(self.Predecessor[curState,:])) :
        #             print '%3d ' % (self.Predecessor[curState,time]) ,              # print all times for a given state as one row 
        #         print '\n'
        #      print "\n"

        # find the most-likely ending state from the last row
        # of the trellis
        # s = self.most_likely_state(n)

        # reconstruct message by tracing the most likely path
        # back through the matrix using self.Predecessor.
        # return self.traceback(s,n)

    # print out final path metrics
    def dump_state(self):
        pass


    def get_prev_states(self, n):
        """ Returns the previous state for the current  survivor path ending at each state """
        return [self.Predecessor[i][n] for i in range(self.nstates)]
        
    def get_desc(self):
        """ Returns the previous decision for the currnent survivor path ending at each state. """
        pass






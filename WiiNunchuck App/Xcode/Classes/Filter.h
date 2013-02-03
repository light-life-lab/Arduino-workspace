class Filter{

public:

	Filter();
	/* Default constructor. Initializes Filter object to
	order 0 all pass filter */

	Filter(double *acoeffs, double *bcoeffs, int ord, int chan);
	/* Initializes filter to given numerator and denominator coefficients
	and expects there to be the appropriate number according to filter order*/
    
    Filter(float cutoff, float reson);
    /*initializes a resonant filter*/

	~Filter();

	//void clear();
	// clears all state buffers
    
    void setReson(float reson);
    
    void setCutoff(float cutoff);

	void process(float *framein, float *frameout, int num_samples, int chan);

private:

	int channels;	// number of channels (for use as a filterbank)
	int order;		// order of each filter
	double *a;		// denominator coefficients
	double *b;		// numerator coefficients
	double *d;		// delay buffers/states

	
	float m_reson;
    float m_cutoff;


};
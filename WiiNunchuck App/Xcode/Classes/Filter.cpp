#include "Filter.h"
#include "AudioBasics.h"
#include <cstdlib>
#include <iostream>

Filter::Filter(){
	//default constructor, order 0 all pass.
	order = 0;
	channels = 1;
	a = NULL;
	d = NULL;
	b = new double[1];
	b[0] = 1;
}

Filter::Filter(double *acoeffs, double *bcoeffs, int ord, int chan){
	int i = 0;

	order = ord;
	channels = chan;

	// The coefficients and states for each channel are laid out one group after the other
	//		ahcobj.a:		a00a01a02...a0N		a10a11a12...a1N		
	//		agcobj.b:		b00b01b02...b0N		b10b11b12...b1N
	//		agcobj.d:		d00d01d02...d0N		d10d11d12...d1N
	//						CHANNEL 0			CHANNEL 1 ...
	a = new double[channels*(order + 1)];
	b = new double[channels*(order + 1)];
	d = new double[channels*(order + 1)];


	for(i = 0; i < (channels*(order + 1)); i += 1){
		b[i] = bcoeffs[i];
		d[i] = 0;
		a[i] = acoeffs[i];

	}

}

Filter::Filter(float cutoff, float reson){
    order		= 2;
    channels	= 1;
    m_reson		= reson;
    m_cutoff	= cutoff;
    
    a = new double[channels*(order + 1)];
	b = new double[channels*(order + 1)];
	d = new double[channels*(order + 1)];
    
    a[2] = pow(reson, 2);
    a[1] = -2.0*reson*cos(2*M_PI*cutoff/44100);
    a[0] = 1.0;
    
    // Normalization (zeros at DC and Nyquist)
    b[0] = 0.5 - 0.5*a[2];
    b[1] = 0.0;
    b[2] = -b[0];
    
    int i;
    for(i = 0; i < (channels*(order + 1)); i += 1)
	{
		d[i] = 0.0;
	}
}

Filter::~Filter(){
	
	delete[] a;
	delete[] b;
	delete[] d;
}

void Filter::setReson(float reson){
	
    m_reson = reson;
    
    a[2] = pow(m_reson, 2);
    a[1] = -2.0*m_reson*cos(2*M_PI*m_cutoff/44100);
    a[0] = 1.0;
    
    // Normalization (zeros at DC and Nyquist)
    b[0] = 0.5 - 0.5*a[2];
    b[1] = 0.0;
    b[2] = -b[0];
}

void Filter::setCutoff(float cutoff){
    
    m_cutoff = cutoff;
    
    a[2] = pow(m_reson, 2);
    a[1] = -2.0*m_reson*cos(2*M_PI*m_cutoff/44100);
    a[0] = 1.0;
    
    // Normalization (zeros at DC and Nyquist)
    b[0] = 0.5 - 0.5*a[2];
    b[1] = 0.0;
    b[2] = -b[0];
}

void Filter::process(float *framein, float *frameout, int num_samples, int chan)
{
	// Filters an input (array) of samples
	
	int i, j, offset;
	double input, feedback, feedforward;

	// chan: channel that we are using to process the frame, lowest channel is channel 0
	offset = chan*(order+1);
	
	for(i = 0; i < num_samples; i += 1){

		input		= (double)framein[i];									
		feedback	= 0;
		feedforward = 0;

		for(j = 1; j <= order; j += 1){
			feedback	+= -(double)a[offset + j]*(double)d[offset + order - j];	//-a(1)v(n-1)-a(2)v(n-2)-a(3)v(n-3)....-a(n)v(0)
			feedforward +=  (double)b[offset + j]*(double)d[offset + order - j];	// b(1)v(n-1)+b(2)v(n-2)....+b(n)v(0)
		}


		d[offset+order] = (float)(input + feedback);								// v(n) = x(n)+feedback = x(n)-a(1)v(n-1)-a(2)v(n-2)-a(3)v(n-3)....-a(n)v(0)
		frameout[i]		= (float)(d[offset + order]*b[offset] + feedforward);		// y(n) = b(0)*v(n) + b(1)v(n-1)+b(2)v(n-2)....+b(n)v(0)

		// Update states
		for(j = 1; j <= order; j += 1){
			d[offset + j - 1] = d[offset + j];
		}
	}

}
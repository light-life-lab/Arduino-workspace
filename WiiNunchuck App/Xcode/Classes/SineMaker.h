#import <Foundation/Foundation.h>

#define kMaxFrequency	6000
#define kMinFrequency	100


@interface SineMaker : NSObject {
	@public BOOL isPlaying;
}

-(void)playSineWave;
-(void)stopSineWave;
-(void)changePitch:(double)value;
-(void)changeVolume:(double)value;

-(void)changeLeftPitchBy:(double)value andCopyToRight:(BOOL)mono;
-(void)changeRightPitchBy:(double)value;
-(void)changeVolumeBy:(double)value;

-(void)changeTremDepth:(double)value;
-(void)changeTremSpeed:(double)value;
-(BOOL)isPlaying;


@end

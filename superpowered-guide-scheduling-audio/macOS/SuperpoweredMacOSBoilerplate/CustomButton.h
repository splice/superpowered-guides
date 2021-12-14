//
//  CustomButton.h
//  SuperpoweredMacOSBoilerplate
//
//  Created by Thomas Dodds on 11/4/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomButton : NSButton

typedef void (^MouseUpBlock)(void);
typedef void (^MouseDownBlock)(void);

@property (nonatomic, copy) MouseUpBlock mouseUpBlock;
@property (nonatomic, copy) MouseDownBlock mouseDownBlock;

@end

NS_ASSUME_NONNULL_END

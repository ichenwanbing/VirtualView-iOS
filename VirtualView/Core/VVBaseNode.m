//
//  VVBaseNode.m
//  VirtualView
//
//  Copyright (c) 2017-2018 Alibaba. All rights reserved.
//

#import "VVBaseNode.h"
#import "UIColor+VirtualView.h"

@interface VVBaseNode ()
{
    NSMutableArray*   _subViews;
    NSUInteger        _objectID;
    int _align, _flag, _minWidth, _minHeight;
    //NSMutableDictionary* _mutablePropertyDic;
}

@end

@implementation VVBaseNode
@synthesize subViews = _subViews;
@synthesize objectID   = _objectID;
//@synthesize mutablePropertyDic   = _mutablePropertyDic;
- (id)init{
    self = [super init];
    if (self) {
        self.alpha = 1.0f;
        self.hidden = NO;
        _subViews = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor clearColor];
        self.gravity = VVGravityLeft|VVGravityTop;
        self.visible = VVVisibilityVisible;
        self.layoutDirection = VVDirectionLeft;
        self.autoDimDirection = VVAutoDimDirectionNone;
    }
    return self;
}
- (BOOL)isClickable{
    if (_flag&VVFlagClickable) {
        return YES;
    }else{
        return NO;
    }
}
- (BOOL)isLongClickable{
    if (_flag&VVFlagLongClickable) {
        return YES;
    }else{
        return NO;
    }
}
- (BOOL)supportExposure{
    if (_flag&VVFlagExposure) {
        return YES;
    }else{
        return NO;
    }

}
-(BOOL)pointInside:(CGPoint)point withView:(VVBaseNode*)vvobj{
    CGFloat x =vvobj.frame.origin.x;
    CGFloat y =vvobj.frame.origin.y;
    CGFloat w =vvobj.frame.size.width;
    CGFloat h =vvobj.frame.size.height;
    if (point.x>x && point.y>y && point.x<w+x && point.y<h+y) {
        return YES;
    }else{
        return NO;
    }
}

-(BOOL)pointInside:(CGPoint)point{
    CGFloat x =self.frame.origin.x;
    CGFloat y =self.frame.origin.y;
    CGFloat w =self.frame.size.width;
    CGFloat h =self.frame.size.height;
    if (point.x>x && point.y>y && point.x<w+x && point.y<h+y) {
        return YES;
    }else{
        return NO;
    }
}

- (id<VVWidgetObject>)hitTest:(CGPoint)point
{
    if (self.visible == VVVisibilityVisible && self.hidden == NO && self.alpha > 0.1f && [self pointInside:point]) {
        if (self.subViews.count > 0) {
            for (VVBaseNode* item in [self.subViews reverseObjectEnumerator]) {
                id<VVWidgetObject> obj = [item hitTest:point];
                if (obj) {
                    return obj;
                }
            }
        }
        if ([self isClickable] || [self isLongClickable]) {
            return self;
        }
    }
    return nil;
}

- (VVBaseNode*)findViewByID:(int)tagid{

    if (self.objectID==tagid) {
        return self;
    }

    VVBaseNode* obj = nil;

    for (VVBaseNode* item in self.subViews) {
        if (/*item.subViews.count==0 &&*/ item.objectID==tagid) {
            obj = item;
            break;
        }else{
            obj = [item findViewByID:tagid];
            break;
        }
    }
    return obj;
}

- (void)addSubview:(VVBaseNode*)view{
    [_subViews addObject:view];
    view.superview = self;
}

- (void)removeSubView:(VVBaseNode*)view{
    [_subViews removeObject:view];
}

- (void)removeFromSuperview{
    [self.superview removeSubView:self];
    self.superview = nil;
}

- (void)setNeedsLayout{
    //
}

- (CGSize)nativeContentSize{
    return CGSizeZero;
}

- (void)layoutSubviews{
    //
    CGFloat x = self.frame.origin.x;
    CGFloat y = self.frame.origin.y;
    _width = _width<0?self.superview.frame.size.width:_width;
    _height = _height<0?self.superview.frame.size.height:_height;
    CGFloat a1,a2,w,h;
    a1 = (int)x*1;
    a2 = (int)y*1;
    w = (int)_width*1;
    h = (int)_height*1;
    self.frame = CGRectMake(a1, a2, w, h);
}

- (CGSize)calculateLayoutSize:(CGSize)maxSize{
    CGSize size={0,0};
    return size;
}

- (void)autoDim{
    switch (self.autoDimDirection) {
        case VVAutoDimDirectionX:
            self.height = self.width*(self.autoDimY/self.autoDimX);
            break;
        case VVAutoDimDirectionY:
            self.width = self.height*(self.autoDimX/self.autoDimY);
        default:
            break;
    }
}

- (void)drawRect:(CGRect)rect{
    //
}

- (void)changeCocoaViewSuperView{
    if (self.cocoaView.superview && self.visible==VVVisibilityGone) {
        [self.cocoaView removeFromSuperview];
    }else if(self.cocoaView.superview==nil && self.visible!=VVVisibilityGone){
        [(UIView*)self.updateDelegate addSubview:self.cocoaView];
    }
}

- (NSString*)getVarName:(NSString*)strValue{
    NSString* valueVarName = nil;
    if(strValue==nil || strValue.length<4){
        return nil;
    }
    NSString* varTagStart = [strValue substringToIndex:2];
    NSRange rangEnd = [strValue rangeOfString:@"}"];
    if ([varTagStart isEqualToString:@"${"] && rangEnd.location!=NSNotFound) {
        valueVarName = [strValue substringWithRange:NSMakeRange(2, rangEnd.location-2)];
    }

    return valueVarName;
}

- (BOOL)setProperty:(int)property valueVar:(NSString *)value{
    BOOL ret = NO;
    if (value!=nil && value.length>3) {
        NSString* varTagStart = [value substringToIndex:2];
        NSRange rangEnd = [value rangeOfString:@"}"];
        int valueType = TYPE_OBJECT;
        switch (property) {
            case STR_ID_autoDimDirection:
            case STR_ID_stayTime:
            case STR_ID_animatorTime:
            case STR_ID_autoSwitchTime:
                valueType = TYPE_INT;
                break;
            case STR_ID_paddingLeft:
            case STR_ID_paddingTop:
            case STR_ID_paddingRight:
            case STR_ID_paddingBottom:
            case STR_ID_layoutMarginLeft:
            case STR_ID_layoutMarginRight:
            case STR_ID_layoutMarginTop:
            case STR_ID_layoutMarginBottom:
            case STR_ID_autoDimX:
            case STR_ID_autoDimY:
            case STR_ID_borderWidth:
            case STR_ID_borderRadius:
            case STR_ID_borderTopLeftRadius:
            case STR_ID_borderTopRightRadius:
            case STR_ID_borderBottomLeftRadius:
            case STR_ID_borderBottomRightRadius:
            case STR_ID_itemHorizontalMargin:
            case STR_ID_itemVerticalMargin:
            case STR_ID_textSize:
                valueType = TYPE_FLOAT;
                break;
            case STR_ID_data:
            case STR_ID_dataUrl:
            case STR_ID_dataParam:
            case STR_ID_action:
            case STR_ID_actionParam:
            case STR_ID_class:
            case STR_ID_name:
            case STR_ID_backgroundImage:
            case STR_ID_src:
            case STR_ID_text:
            case STR_ID_ck:
                valueType = TYPE_STRING;
                break;
            case STR_ID_color:
            case STR_ID_textColor:
            case STR_ID_borderColor:
            case STR_ID_maskColor:
            case STR_ID_background:
                valueType = TYPE_COLOR;
                break;
            case STR_ID_autoSwitch:
            case STR_ID_canSlide:
            case STR_ID_inmainthread:
                valueType = TYPE_BOOLEAN;
                break;
            case STR_ID_visibility:
                valueType = TYPE_VISIBILITY;
                break;
            case STR_ID_gravity:
                valueType = TYPE_GRAVITY;
                break;
            case STR_ID_dataTag:
                valueType = TYPE_OBJECT;
                break;
            default:
                valueType = TYPE_OBJECT;
                break;
        }
        if ([varTagStart isEqualToString:@"${"] && rangEnd.location!=NSNotFound) {
            NSString* valueVarName = [value substringWithRange:NSMakeRange(2, rangEnd.location-2)];
            NSNumber* propertyNum = [NSNumber numberWithUnsignedInteger:property];
            if (valueVarName!=nil && valueVarName.length>0 && propertyNum!=nil) {
                if (self.mutablePropertyDic==nil) {
                    self.mutablePropertyDic = [[NSMutableDictionary alloc] init];
                }
                NSArray* nodes = [valueVarName componentsSeparatedByString:@"."];
                NSMutableArray* varList = [[NSMutableArray alloc] initWithCapacity:nodes.count];
                for (NSString* node in nodes) {
                    //NSLog(@"%@",node);
                    NSRange start = [node rangeOfString:@"["];
                    NSRange end   = [node rangeOfString:@"]"];
                    if (start.location!=NSNotFound && end.location!=NSNotFound && start.location<end.location) {
                        NSRange indexRange = NSMakeRange(start.location+1, end.location-start.location-1);
                        NSString* indexString = [node substringWithRange:indexRange];
                        NSUInteger index = [indexString integerValue];
                        NSString* nodeName = [node substringToIndex:start.location];
                        [varList addObject:[NSDictionary dictionaryWithObjectsAndKeys:nodeName,@"varName",[NSNumber numberWithUnsignedInteger:index],@"varIndex", nil]];
                    }else{
                        [varList addObject:[NSDictionary dictionaryWithObjectsAndKeys:node,@"varName",[NSNumber numberWithInt:-1],@"varIndex", nil]];
                    }
                }
                NSDictionary* propertyInfo = [NSDictionary dictionaryWithObjectsAndKeys:varList,@"varValues",[NSNumber numberWithInt:valueType],@"valueType", nil];
                

                [self.mutablePropertyDic setObject:propertyInfo forKey:propertyNum];
                ret = YES;
            }
        }else if ([varTagStart isEqualToString:@"@{"] && rangEnd.location!=NSNotFound){
            NSRange r2,r3;
            NSString* valueVarName = [value substringWithRange:NSMakeRange(2, rangEnd.location-1)];
            NSNumber* propertyNum = [NSNumber numberWithUnsignedInteger:property];
            NSRange r1 = [value rangeOfString:@"?" options:NSCaseInsensitiveSearch range:NSMakeRange(rangEnd.location, value.length-rangEnd.location)];
            
            if (r1.location!=NSNotFound) {
                r2 = [value rangeOfString:@":" options:NSCaseInsensitiveSearch range:NSMakeRange(r1.location, value.length-r1.location)];
                
                if (r2.location!=NSNotFound) {
                    r3 = [value rangeOfString:@"}" options:NSCaseInsensitiveSearch | NSBackwardsSearch range:NSMakeRange(r2.location, value.length-r2.location)];
                    
                    if (r3.location!=NSNotFound) {
                        NSString* v1 = [value substringWithRange:NSMakeRange(r1.location+1, r2.location-r1.location-1)];
                        NSString* v2 = [value substringWithRange:NSMakeRange(r2.location+1, r3.location-r2.location-1)];
                        NSString* vv1 =[v1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        NSString* vv2 =[v2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                        NSString* vv0VarName = [self getVarName:valueVarName];
                        NSObject* vv0VarInfo;
                        if (vv0VarName) {
                            NSArray* nodes = [vv0VarName componentsSeparatedByString:@"."];
                            vv0VarInfo = [[NSMutableArray alloc] initWithCapacity:nodes.count];
                            for (NSString* node in nodes) {
                                //NSLog(@"%@",node);
                                NSRange start = [node rangeOfString:@"["];
                                NSRange end   = [node rangeOfString:@"]"];
                                if (start.location!=NSNotFound && end.location!=NSNotFound && start.location<end.location) {
                                    NSRange indexRange = NSMakeRange(start.location+1, end.location-start.location-1);
                                    NSString* indexString = [node substringWithRange:indexRange];
                                    NSUInteger index = [indexString integerValue];
                                    NSString* nodeName = [node substringToIndex:start.location];
                                    [(NSMutableArray*)vv0VarInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:nodeName,@"varName",[NSNumber numberWithUnsignedInteger:index],@"varIndex", nil]];

                                }else{
                                    [(NSMutableArray*)vv0VarInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:node,@"varName",[NSNumber numberWithInt:-1],@"varIndex", nil]];
                                }

                            }
                        }else{
                            vv0VarInfo = valueVarName;
                        }


                        NSString* vv1VarName = [self getVarName:vv1];
                        NSObject* vv1VarInfo;
                        if (vv1VarName) {
                            NSArray* vv1Nodes = [vv1VarName componentsSeparatedByString:@"."];
                            vv1VarInfo = [[NSMutableArray alloc] initWithCapacity:vv1Nodes.count];
                            for (NSString* node in vv1Nodes) {
                                //NSLog(@"%@",node);
                                NSRange start = [node rangeOfString:@"["];
                                NSRange end   = [node rangeOfString:@"]"];
                                if (start.location!=NSNotFound && end.location!=NSNotFound && start.location<end.location) {
                                    NSRange indexRange = NSMakeRange(start.location+1, end.location-start.location-1);
                                    NSString* indexString = [node substringWithRange:indexRange];
                                    NSUInteger index = [indexString integerValue];
                                    NSString* nodeName = [node substringToIndex:start.location];
                                    [(NSMutableArray*)vv1VarInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:nodeName,@"varName",[NSNumber numberWithUnsignedInteger:index],@"varIndex", nil]];

                                }else{
                                    [(NSMutableArray*)vv1VarInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:node,@"varName",[NSNumber numberWithInt:-1],@"varIndex", nil]];
                                }

                            }
                        }else{
                            vv1VarInfo = vv1;
                        }

                        NSString* vv2VarName = [self getVarName:vv2];
                        NSObject* vv2VarInfo;
                        if (vv2VarName) {
                            NSArray* vv2Nodes = [vv2VarName componentsSeparatedByString:@"."];
                            vv2VarInfo = [[NSMutableArray alloc] initWithCapacity:vv2Nodes.count];
                            for (NSString* node in vv2Nodes) {
                                //NSLog(@"%@",node);
                                NSRange start = [node rangeOfString:@"["];
                                NSRange end   = [node rangeOfString:@"]"];
                                if (start.location!=NSNotFound && end.location!=NSNotFound && start.location<end.location) {
                                    NSRange indexRange = NSMakeRange(start.location+1, end.location-start.location-1);
                                    NSString* indexString = [node substringWithRange:indexRange];
                                    NSUInteger index = [indexString integerValue];
                                    NSString* nodeName = [node substringToIndex:start.location];
                                    [(NSMutableArray*)vv2VarInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:nodeName,@"varName",[NSNumber numberWithUnsignedInteger:index],@"varIndex", nil]];

                                }else{
                                    [(NSMutableArray*)vv2VarInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:node,@"varName",[NSNumber numberWithInt:-1],@"varIndex", nil]];
                                }

                            }
                        }else{
                            vv2VarInfo = vv2;
                        }

                        NSDictionary* propertyInfo = [NSDictionary dictionaryWithObjectsAndKeys:vv0VarInfo,@"varValues",[NSNumber numberWithInt:valueType],@"valueType",vv1VarInfo,@"v1",vv2VarInfo,@"v2", nil];
                        
                        if (self.mutablePropertyDic==nil) {
                            self.mutablePropertyDic = [[NSMutableDictionary alloc] init];
                        }
                        
                        [self.mutablePropertyDic setObject:propertyInfo forKey:propertyNum];
                        ret = YES;
                    }
                }
            }
        }
        if (property==STR_ID_action) {
            //self.action = strValueVar;
        }
    }else if (property==STR_ID_action){
        //
        //self.action = strValueVar;
    }

    return ret;
}

- (BOOL)setIntValue:(int)value forKey:(int)key{
    BOOL ret = YES;
    switch (key) {

        case STR_ID_layoutWidth:
            _widthModle = value;
            _width = value>0?value:0;
            self.frame = CGRectMake(0, 0, _width, _height);
            break;
        case STR_ID_layoutHeight:
            _heightModle = value;
            _height = value>0?value:0;
            self.frame = CGRectMake(0, 0, _width, _height);
            break;
        case STR_ID_paddingLeft:
            _paddingLeft = value;
            break;
        case STR_ID_paddingTop:
            _paddingTop = value;
            break;
        case STR_ID_paddingRight:
            _paddingRight = value;
            break;
        case STR_ID_paddingBottom:
            _paddingBottom = value;
            break;
        case STR_ID_layoutMarginLeft:
            _marginLeft = value;
            break;
        case STR_ID_layoutMarginTop:
            _marginTop = value;
            break;
        case STR_ID_layoutMarginRight:
            _marginRight = value;
            break;
        case STR_ID_layoutMarginBottom:
            _marginBottom = value;
            break;
        case STR_ID_layoutGravity:
            _layoutGravity = value;
            break;
        case STR_ID_id:
            _objectID = value;
            break;
        case STR_ID_background:
            self.backgroundColor = [UIColor colorWithHexValue:value];
            break;
            
        case STR_ID_gravity:
            self.gravity = value;
            break;
            
        case STR_ID_flag:
            _flag = value;
            break;
            
        case STR_ID_minWidth:
            _minWidth = value;
            break;
        case STR_ID_minHeight:
            _minHeight = value;
            break;
            
        case STR_ID_uuid:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_uuid:%d",value);
            #endif
            break;
            
        case STR_ID_autoDimDirection:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_autoDimDirection:%d",value);
            #endif
            _autoDimDirection = value;
            break;
            
        case STR_ID_autoDimX:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_autoDimX:%d",value);
            #endif
            _autoDimX = value;
            break;
            
        case STR_ID_autoDimY:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_autoDimY:%d",value);
            #endif
            _autoDimY = value;
            break;
        case STR_ID_layoutRatio:
            self.layoutRatio = value;
            break;
        case STR_ID_visibility:
            self.visible = value;
            switch (self.visible) {
                case VVVisibilityInvisible:
                    self.hidden = YES;
                    self.cocoaView.hidden = YES;
                    break;
                case VVVisibilityVisible:
                    self.hidden = NO;
                    self.cocoaView.hidden = NO;
                    break;
                case VVVisibilityGone:
                    self.hidden = YES;
                    self.cocoaView.hidden = YES;
                    break;
            }
            [self changeCocoaViewSuperView];
            break;
        case STR_ID_layoutDirection:
            self.layoutDirection = value;
        default:
            ret = false;
    }

    return ret;
}

- (BOOL)setFloatValue:(float)value forKey:(int)key{
    BOOL ret = YES;
    switch (key) {

        case STR_ID_layoutWidth:
            _widthModle = value;
            _width = value>0?value:0;
            self.frame = CGRectMake(0, 0, _width, _height);
            break;
        case STR_ID_layoutHeight:
            _heightModle = value;
            _height = value>0?value:0;
            self.frame = CGRectMake(0, 0, _width, _height);
            break;
        case STR_ID_paddingLeft:
            _paddingLeft = value;
            break;
        case STR_ID_paddingTop:
            _paddingTop = value;
            break;
        case STR_ID_paddingRight:
            _paddingRight = value;
            break;
        case STR_ID_paddingBottom:
            _paddingBottom = value;
            break;
        case STR_ID_layoutMarginLeft:
            _marginLeft = value;
            break;
        case STR_ID_layoutMarginTop:
            _marginTop = value;
            break;
        case STR_ID_layoutMarginRight:
            _marginRight = value;
            break;
        case STR_ID_layoutMarginBottom:
            _marginBottom = value;
            break;
        case STR_ID_layoutGravity:
            _layoutGravity = value;
            break;
        case STR_ID_id:
            _objectID = value;
            break;
        case STR_ID_background:
            self.backgroundColor = [UIColor colorWithHexValue:(int)value];
            break;
            
        case STR_ID_gravity:
            self.gravity = value;
            break;
            
        case STR_ID_flag:
            _flag = value;
            break;
            
        case STR_ID_minWidth:
            _minWidth = value;
            break;
        case STR_ID_minHeight:
            _minHeight = value;
            break;
            
        case STR_ID_uuid:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_uuid:%f",value);
            #endif
            break;
            
        case STR_ID_autoDimDirection:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_autoDimDirection:%f",value);
            #endif
            _autoDimDirection = value;
            break;
            
        case STR_ID_autoDimX:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_autoDimX:%f",value);
            #endif
            _autoDimX = value;
            break;
            
        case STR_ID_autoDimY:
            #ifdef VV_DEBUG
                NSLog(@"STR_ID_autoDimY:%f",value);
            #endif
            _autoDimY = value;
            break;
        case STR_ID_layoutRatio:
            self.layoutRatio = value;
            break;
        case STR_ID_visibility:
            self.visible = value;
            switch (self.visible) {
                case VVVisibilityInvisible:
                    self.hidden = YES;
                    self.cocoaView.hidden = YES;
                    break;
                case VVVisibilityVisible:
                    self.hidden = NO;
                    self.cocoaView.hidden = NO;
                    break;
                case VVVisibilityGone:
                    //
                    break;
            }
            [self changeCocoaViewSuperView];
            break;
        default:
            ret = false;
            break;
    }
    
    return ret;
}

- (BOOL)setStringValue:(NSString *)value forKey:(int)key
{
    BOOL ret = [self setProperty:key valueVar:value];
    if (!ret) {
        ret = YES;
        switch (key) {

            case STR_ID_data:
                break;

            case STR_ID_dataTag:
                self.dataTag = value;
                break;

            case STR_ID_action:
                self.action = value;
                break;

            case STR_ID_actionParam:
                self.actionParam = value;
                break;

            case STR_ID_class:
                self.classString = value;
                break;

            case STR_ID_name:
                self.name = value;
                break;

            case STR_ID_dataUrl:
                self.dataUrl = value;
                break;
            case STR_ID_background:
                self.backgroundColor = [UIColor colorWithString:value];
                break;
            default:
                ret = NO;
        }
    }
    
    return ret;
}

- (BOOL)setStringDataValue:(NSString*)value forKey:(int)key{
    BOOL ret = true;
    switch (key) {
        case STR_ID_onClick:
            //mClickCode = value;
            //                Log.d(TAG, "click value:" + mClickCode + " id:" + mId);
            break;
            
        case STR_ID_onBeforeDataLoad:
            //mBeforeLoadDataCode = value;
            break;
            
        case STR_ID_onAfterDataLoad:
            //mAfterLoadDataCode = value;
            break;
            
        case STR_ID_onSetData:
            //mSetDataCode = value;
            break;
            
        default:
            ret = false;
    }
    
    return ret;
}

- (void)reset{
    //
}

- (void)didFinishBinding
{
    
}

- (void)dataUpdateFinished{
    [self layoutSubviews];
}

- (void)setData:(NSData*)data{
    //
}

- (void)setDataObj:(NSObject*)obj forKey:(int)key{
    //NSObject* data = [dic objectForKey:self.dataTag];
    //NSDictionary* tmpDictionary = dic;
    //NSArray* peropertys = [_mutablePropertyDic allKeys];
    /*
    for (NSNumber* peropertyNum in peropertys) {
        NSString* valueVar = [_mutablePropertyDic objectForKey:peropertyNum];
        
        NSArray* nodes = [valueVar componentsSeparatedByString:@"."];
        NSObject* valueObj;

        for (NSString* node in nodes) {
            NSLog(@"%@",node);
            NSRange start = [node rangeOfString:@"["];
            NSRange end   = [node rangeOfString:@"]"];
            if (start.location!=NSNotFound && end.location!=NSNotFound && start.location<end.location) {
                NSRange indexRange = NSMakeRange(start.location+1, end.location-start.location);
                NSString* indexString = [node substringWithRange:indexRange];
                NSUInteger index = [indexString integerValue];
                NSString* nodeName = [node substringToIndex:start.location];
                NSArray* items = [tmpDictionary objectForKey:nodeName];
                valueObj = [items objectAtIndex:index];

            }else{
                valueObj = [tmpDictionary objectForKey:node];
            }
            
            if ([valueObj isKindOfClass:NSDictionary.class]) {
                tmpDictionary = (NSDictionary*)valueObj;
            }
        }
        
        switch ([peropertyNum unsignedIntValue]) {
            case 0:
                //
                break;
                
            default:
                break;
        }
     
        //NSObject* valueObj = [dic objectForKey:valueVar];
        NSString* singleChar = [peroperty substringToIndex:0];
        NSString* bstr = [peroperty substringFromIndex:1];
        NSString* method = [NSString stringWithFormat:@"set%@%@:",[singleChar uppercaseString],bstr];
        SEL smthd = NSSelectorFromString(method);
        if ([self respondsToSelector:smthd]) {
            IMP imp = [self methodForSelector:smthd];
            void (*func)(id, SEL, NSObject*) = (void *)imp;
            func(self,smthd,valueObj);
        }
    }*/
    /*
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新界面
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.updateDelegate updateDisplayRect:self.frame];
    });*/
}

- (void)setTagsValue:(NSArray*)tags withData:(NSDictionary*)dic{
    //
    NSArray* peropertys = [_mutablePropertyDic allKeys];
    for (NSString* peroperty in peropertys) {
        NSString* valueKey = [_mutablePropertyDic objectForKey:peroperty];
        NSObject* valueObj = [dic objectForKey:valueKey];
        NSString* singleChar = [peroperty substringToIndex:0];
        NSString* bstr = [peroperty substringFromIndex:1];
        NSString* method = [NSString stringWithFormat:@"set%@%@:",[singleChar uppercaseString],bstr];
        SEL smthd = NSSelectorFromString(method);
        if ([self respondsToSelector:smthd]) {
            IMP imp = [self methodForSelector:smthd];
            void (*func)(id, SEL, NSObject*) = (void *)imp;
            func(self,smthd,valueObj);
        }
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新界面
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.updateDelegate updateDisplayRect:self.frame];
    });
}

- (void)setUpdateDelegate:(id<VVWidgetAction>)delegate{
    _updateDelegate = delegate;
    for (VVBaseNode* subObj in self.subViews) {
        subObj.updateDelegate = delegate;
    }
}

@end
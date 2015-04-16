/*
 * Cocos2D-SpriteBuilder: http://cocos2d.spritebuilder.com
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2013-2014 Cocos2D Authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "ccUtils.h"

#import "CCSprite_Private.h"
#import "CCSpriteFrame.h"

#import "CCRenderer.h"
#import "CCTexture.h"
#import "CCTextureCache.h"


#pragma mark -
#pragma mark CCSprite

@implementation CCSprite {
	// Offset Position, used by sprite sheet editors.
	CGPoint _unflippedOffsetPositionFromCenter;

	BOOL _flipX, _flipY;
}

+(instancetype)spriteWithImageNamed:(NSString*)imageName
{
    return [[[self alloc] initWithImageNamed:imageName] autorelease];
}

+(instancetype)spriteWithTexture:(CCTexture*)texture
{
	return [[[self alloc] initWithTexture:texture] autorelease];
}

+(instancetype)spriteWithTexture:(CCTexture*)texture rect:(CGRect)rect
{
	return [[[self alloc] initWithTexture:texture rect:rect] autorelease];
}

+(instancetype)spriteWithFile:(NSString*)filename
{
	return [[[self alloc] initWithFile:filename] autorelease];
}

+(instancetype)spriteWithFile:(NSString*)filename rect:(CGRect)rect
{
	return [[[self alloc] initWithFile:filename rect:rect] autorelease];
}

+(instancetype)spriteWithSpriteFrame:(CCSpriteFrame*)spriteFrame
{
	return [[[self alloc] initWithSpriteFrame:spriteFrame] autorelease];
}

+(instancetype)spriteWithSpriteFrameName:(NSString*)spriteFrameName
{
	CCSpriteFrame *frame = [CCSpriteFrame frameWithImageNamed:spriteFrameName];

	NSAssert1(frame!=nil, @"Invalid spriteFrameName: %@", spriteFrameName);
	return [[self spriteWithSpriteFrame:frame] autorelease];
}

+(instancetype)spriteWithCGImage:(CGImageRef)image key:(NSString*)key
{
	return [[[self alloc] initWithCGImage:image key:key] autorelease];
}

+(instancetype) emptySprite
{
    return [[[self alloc] init] autorelease];
}

-(id) init
{
	return [self initWithTexture:nil rect:CGRectZero];
}

// designated initializer
-(id) initWithTexture:(CCTexture*)texture rect:(CGRect)rect rotated:(BOOL)rotated
{
	if((self = [super init])){
		self.blendMode = [CCBlendMode premultipliedAlphaMode];
		self.shader = [CCShader positionTextureColorShader];
		
		_flipY = _flipX = NO;

		// default transform anchor: center
		self.anchorPoint =  ccp(0.5f, 0.5f);

		// zwoptex default values
		_offsetPosition = CGPointZero;
		
		[self updateColor];
		
		[self setTexture:texture];
		[self setTextureRect:rect rotated:rotated untrimmedSize:rect.size];
	}
	
	return self;
}

- (id) initWithImageNamed:(NSString*)imageName
{
    return [self initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:imageName]];
}

-(id) initWithTexture:(CCTexture*)texture rect:(CGRect)rect
{
	return [self initWithTexture:texture rect:rect rotated:NO];
}

-(id) initWithTexture:(CCTexture*)texture
{
	NSAssert(texture!=nil, @"Invalid texture for sprite");

	CGRect rect = CGRectZero;
	rect.size = texture.contentSize;
	return [self initWithTexture:texture rect:rect];
}

-(id) initWithFile:(NSString*)filename
{
	NSAssert(filename != nil, @"Invalid filename for sprite");

	CCTexture *texture = [[CCTextureCache sharedTextureCache] addImage: filename];
	if( texture ) {
		CGRect rect = CGRectZero;
		rect.size = texture.contentSize;
		return [self initWithTexture:texture rect:rect];
	}

	return nil;
}

-(id) initWithFile:(NSString*)filename rect:(CGRect)rect
{
	NSAssert(filename!=nil, @"Invalid filename for sprite");

	CCTexture *texture = [[CCTextureCache sharedTextureCache] addImage: filename];
	if( texture )
		return [self initWithTexture:texture rect:rect];

	return nil;
}

- (id) initWithSpriteFrame:(CCSpriteFrame*)spriteFrame
{
	NSAssert(spriteFrame!=nil, @"Invalid spriteFrame for sprite");

	id ret = [self initWithTexture:spriteFrame.texture rect:spriteFrame.rect];
    self.spriteFrame = spriteFrame;
	return ret;
}

-(id)initWithSpriteFrameName:(NSString*)spriteFrameName
{
	NSAssert(spriteFrameName!=nil, @"Invalid spriteFrameName for sprite");

	CCSpriteFrame *frame = [CCSpriteFrame frameWithImageNamed:spriteFrameName];
	return [self initWithSpriteFrame:frame];
}

- (id) initWithCGImage:(CGImageRef)image key:(NSString*)key
{
	NSAssert(image!=nil, @"Invalid CGImageRef for sprite");

	// XXX: possible bug. See issue #349. New API should be added
	CCTexture *texture = [[CCTextureCache sharedTextureCache] addCGImage:image forKey:key];

	CGRect rect = CGRectZero;
	rect.size = texture.contentSize;

	return [self initWithTexture:texture rect:rect];
}

-(void)dealloc
{
    [_spriteFrame release]; _spriteFrame = nil;
    [_normalMapSpriteFrame release]; _normalMapSpriteFrame = nil;
    [_effect release]; _effect = nil;
    [_effectRenderer release]; _effectRenderer = nil;
    
    [super dealloc];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %p | Rect = (%.2f,%.2f,%.2f,%.2f) | Name = %@ >",
		[self class], self, _textureRect.origin.x, _textureRect.origin.y, _textureRect.size.width, _textureRect.size.height, self.name
	];
}

-(void) setTextureRect:(CGRect)rect
{
	[self setTextureRect:rect rotated:NO untrimmedSize:rect.size];
}

-(void) setTextureRect:(CGRect)rect rotated:(BOOL)rotated untrimmedSize:(CGSize)untrimmedSize
{
    [self setTextureRect:rect forTexture:self.texture rotated:rotated untrimmedSize:untrimmedSize];
}

- (void)setTextureRect:(CGRect)rect forTexture:(CCTexture*)texture rotated:(BOOL)rotated untrimmedSize:(CGSize)untrimmedSize
{
	_textureRectRotated = rotated;
    
	self.contentSizeType = CCSizeTypePoints;
	[self setContentSize:untrimmedSize];
	_textureRect = rect;
    
	CCSpriteTexCoordSet texCoords = [CCSprite textureCoordsForTexture:texture withRect:rect rotated:rotated xFlipped:_flipX yFlipped:_flipY];
    _verts.bl.texCoord1 = texCoords.bl;
    _verts.br.texCoord1 = texCoords.br;
    _verts.tr.texCoord1 = texCoords.tr;
    _verts.tl.texCoord1 = texCoords.tl;
    
    
	CGPoint relativeOffset = _unflippedOffsetPositionFromCenter;

	// issue #732
	if(_flipX) relativeOffset.x = -relativeOffset.x;
	if(_flipY) relativeOffset.y = -relativeOffset.y;
	
	CGSize size = self.contentSize;
	_offsetPosition.x = relativeOffset.x + (size.width - _textureRect.size.width) / 2;
	_offsetPosition.y = relativeOffset.y + (size.height - _textureRect.size.height) / 2;

	// Atlas: Vertex
	float x1 = _offsetPosition.x;
	float y1 = _offsetPosition.y;
	float x2 = x1 + _textureRect.size.width;
	float y2 = y1 + _textureRect.size.height;
	
	_verts.bl.position = GLKVector4Make(x1, y1, 0.0f, 1.0f);
	_verts.br.position = GLKVector4Make(x2, y1, 0.0f, 1.0f);
	_verts.tr.position = GLKVector4Make(x2, y2, 0.0f, 1.0f);
	_verts.tl.position = GLKVector4Make(x1, y2, 0.0f, 1.0f);
	
	// Set the center/extents for culling purposes.
	_vertexCenter = GLKVector2Make((x1 + x2)*0.5f, (y1 + y2)*0.5f);
	_vertexExtents = GLKVector2Make((x2 - x1)*0.5f, (y2 - y1)*0.5f);
}

+ (CCSpriteTexCoordSet)textureCoordsForTexture:(CCTexture *)texture withRect:(CGRect)rect rotated:(BOOL)rotated xFlipped:(BOOL)flipX yFlipped:(BOOL)flipY
{
    CCSpriteTexCoordSet result;
	if(!texture) return result;
	
	CGFloat scale = texture.contentScale;
	rect = CC_RECT_SCALE(rect, scale);
	
    CGSize sizeInPixels = texture.sizeInPixels;
	float atlasWidth = sizeInPixels.width;
	float atlasHeight = sizeInPixels.height;

	if(rotated){
#if CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
		float left   = (2.0f*rect.origin.x + 1.0f)/(2.0f*atlasWidth);
		float right  = left+(rect.size.height*2.0f - 2.0f)/(2.0f*atlasWidth);
		float top    = 1.0f - (2.0f*rect.origin.y + 1.0f)/(2.0f*atlasHeight);
		float bottom = 1.0f - top+(rect.size.width*2.0f - 2.0f)/(2.0f*atlasHeight);
#else
		float left   = rect.origin.x/atlasWidth;
		float right  = (rect.origin.x + rect.size.height)/atlasWidth;
		float top    = 1.0f - rect.origin.y/atlasHeight;
		float bottom = 1.0f - (rect.origin.y + rect.size.width)/atlasHeight;
#endif

		if(flipX) CC_SWAP(top,bottom);
		if(flipY) CC_SWAP(left,right);
		
		result.bl = GLKVector2Make( left,    top);
		result.br = GLKVector2Make( left, bottom);
		result.tr = GLKVector2Make(right, bottom);
		result.tl = GLKVector2Make(right,    top);
	} else {
#if CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
		float left   = (2.0f*rect.origin.x + 1.0f)/(2.0f*atlasWidth);
		float right  = left + (rect.size.width*2.0f - 2.0f)/(2.0f*atlasWidth);
		float top    = 1.0f - (2.0f*rect.origin.y + 1.0f)/(2.0f*atlasHeight);
		float bottom = 1.0f - top + (rect.size.height*2.0f - 2.0f)/(2.0f*atlasHeight);
#else
		float left   = rect.origin.x/atlasWidth;
		float right  = (rect.origin.x + rect.size.width)/atlasWidth;
		float top    = 1.0f - rect.origin.y/atlasHeight;
		float bottom = 1.0f - (rect.origin.y + rect.size.height)/atlasHeight;
#endif

		if(flipX) CC_SWAP(left,right);
		if(flipY) CC_SWAP(top,bottom);

		result.bl = GLKVector2Make( left, bottom);
		result.br = GLKVector2Make(right, bottom);
		result.tr = GLKVector2Make(right,    top);
		result.tl = GLKVector2Make( left,    top);
	}
    
    return result;
}

-(const CCSpriteVertexes *)vertexes
{
	return &_verts;
}

- (GLKMatrix4)nodeToTextureTransform
{
    CGFloat sx = (_verts.br.texCoord1.s - _verts.bl.texCoord1.s) / (_verts.br.position.x - _verts.bl.position.x);
    CGFloat sy = (_verts.tl.texCoord1.t - _verts.bl.texCoord1.t) / (_verts.tl.position.y - _verts.bl.position.y);
    CGFloat tx = (_verts.bl.texCoord1.s - _verts.bl.position.x * sx);
    CGFloat ty = (_verts.bl.texCoord1.t - _verts.bl.position.y * sy);
    
	return GLKMatrix4Make(
		  sx, 0.0f, 0.0f, 0.0f,
		0.0f,   sy, 0.0f, 0.0f,
		0.0f, 0.0f, 1.0f, 0.0f,
		  tx,   ty, 0.0f, 1.0f
	);
}

#pragma mark CCSprite - draw

static inline void
EnqueueTriangles(CCSprite *self, CCRenderer *renderer, const GLKMatrix4 *transform)
{
	CCRenderState *state = self->_renderState ?: self.renderState;
	CCRenderBuffer buffer = [renderer enqueueTriangles:2 andVertexes:4 withState:state globalSortOrder:0];
	
	CCRenderBufferSetVertex(buffer, 0, CCVertexApplyTransform(self->_verts.bl, transform));
	CCRenderBufferSetVertex(buffer, 1, CCVertexApplyTransform(self->_verts.br, transform));
	CCRenderBufferSetVertex(buffer, 2, CCVertexApplyTransform(self->_verts.tr, transform));
	CCRenderBufferSetVertex(buffer, 3, CCVertexApplyTransform(self->_verts.tl, transform));

	CCRenderBufferSetTriangle(buffer, 0, 0, 1, 2);
	CCRenderBufferSetTriangle(buffer, 1, 0, 2, 3);
}

-(void)draw:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform;
{
	if(!CCRenderCheckVisibility(transform, _vertexCenter, _vertexExtents)) return;
	
	if (_effect)
	{
		_effectRenderer.contentSize = self.contentSizeInPoints;
        
        CCEffectPrepareResult prepResult = [self.effect prepareForRenderingWithSprite:self];
        NSAssert(prepResult.status == CCEffectPrepareSuccess, @"Effect preparation failed.");
        
        if (prepResult.changes & CCEffectPrepareUniformsChanged)
		{
			// Preparing an effect for rendering can modify its uniforms
			// dictionary which means we need to reinitialize our copy of the
			// uniforms.
			[self updateShaderUniformsFromEffect];
		}
		[_effectRenderer drawSprite:self withEffect:self.effect uniforms:_shaderUniforms renderer:renderer transform:transform];
	}
	else
	{
		EnqueueTriangles(self, renderer, transform);
	}
}

-(void)enqueueTriangles:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform
{
	EnqueueTriangles(self, renderer, transform);
}

#pragma mark CCSprite - CCNode overrides

//
// CCNode property overloads
// used only when parent is CCSpriteBatchNode
//
#pragma mark CCSprite - property overloads

-(void)setFlipX:(BOOL)b
{
	if( _flipX != b ) {
		_flipX = b;
		[self setTextureRect:_textureRect rotated:_textureRectRotated untrimmedSize:self.contentSize];
	}
}
-(BOOL) flipX
{
	return _flipX;
}

-(void) setFlipY:(BOOL)b
{
	if( _flipY != b ) {
		_flipY = b;
		[self setTextureRect:_textureRect rotated:_textureRectRotated untrimmedSize:self.contentSize];
	}
}
-(BOOL) flipY
{
	return _flipY;
}

//
// RGBA protocol
//
#pragma mark CCSprite - RGBA protocol
-(void) updateColor
{
	GLKVector4 color4 = GLKVector4Make(_displayColor.r, _displayColor.g, _displayColor.b, _displayColor.a);
	
	// Premultiply alpha.
	color4.r *= _displayColor.a;
	color4.g *= _displayColor.a;
	color4.b *= _displayColor.a;
	
	_verts.bl.color = color4;
	_verts.br.color = color4;
	_verts.tr.color = color4;
	_verts.tl.color = color4;
}

-(void) setColor:(CCColor*)color
{
	[super setColor:color];
	[self updateColor];
}

- (void) setColorRGBA:(CCColor*)color
{
	[super setColorRGBA:color];
	[self updateColor];
}

-(void)updateDisplayedColor:(GLKVector4) parentColor
{
	[super updateDisplayedColor:parentColor];
	[self updateColor];
}

-(void) setOpacity:(CGFloat)opacity
{
	[super setOpacity:opacity];
	[self updateColor];
}

-(void)updateDisplayedOpacity:(CGFloat)parentOpacity
{
    [super updateDisplayedOpacity:parentOpacity];
    [self updateColor];
}

-(CCEffect *)effect
{
	return _effect;
}

-(void)setEffect:(CCEffect *)effect
{
    if(effect != _effect){
        [_effect release];
        _effect = [effect retain];
        
        if(effect){
            if(_effectRenderer == nil){
                _effectRenderer = [[CCEffectRenderer alloc] init];
            }
            
            [self updateShaderUniformsFromEffect];
        } else {
            [_shaderUniforms release];
            _shaderUniforms = nil;
        }
    }
}

//
// Frames
//
#pragma mark CCSprite - Frames

-(void) setSpriteFrame:(CCSpriteFrame*)frame
{
	_unflippedOffsetPositionFromCenter = frame.trimOffset;

	CCTexture *newTexture = [frame texture];
	// update texture before updating texture rect
	if(newTexture != self.texture){
		[self setTexture: newTexture];
	}

	// update rect
	[self setTextureRect:frame.rect rotated:frame.rotated untrimmedSize:frame.untrimmedSize];
    
    [_spriteFrame autorelease];
    _spriteFrame = [frame retain];
}

-(void) setNormalMapSpriteFrame:(CCSpriteFrame*)frame
{
    if (!self.texture)
    {
        // If there is no texture set on the sprite, set the sprite's texture rect from the
        // normal map's sprite frame. Note that setting the main texture, then the normal map,
        // and then removing the main texture will leave the texture rect from the main texture.
        [self setTextureRect:frame.rect forTexture:frame.texture rotated:frame.rotated untrimmedSize:frame.untrimmedSize];
    }

    // Set the second texture coordinate set from the normal map's sprite frame.
    CCSpriteTexCoordSet texCoords = [CCSprite textureCoordsForTexture:frame.texture withRect:frame.rect rotated:frame.rotated xFlipped:_flipX yFlipped:_flipY];
    _verts.bl.texCoord2 = texCoords.bl;
    _verts.br.texCoord2 = texCoords.br;
    _verts.tr.texCoord2 = texCoords.tr;
    _verts.tl.texCoord2 = texCoords.tl;
    
    // Set the normal map texture in the uniforms dictionary (if the dictionary exists).
    self.shaderUniforms[CCShaderUniformNormalMapTexture] = (frame.texture ?: [CCTexture none]);
    [_renderState release];
    _renderState = nil;
    
    [_normalMapSpriteFrame autorelease];
    _normalMapSpriteFrame = [frame retain];
}


//-(void) setSpriteFrameWithAnimationName: (NSString*) animationName index:(int) frameIndex
//{
//	NSAssert( animationName, @"CCSprite#setSpriteFrameWithAnimationName. animationName must not be nil");
//	
//	CCAnimation *a = [[CCAnimationCache sharedAnimationCache] animationByName:animationName];
//	NSAssert( a, @"CCSprite#setSpriteFrameWithAnimationName: Frame not found");
//	
//	CCAnimationFrame *frame = [[a frames] objectAtIndex:frameIndex];
//	NSAssert( frame, @"CCSprite#setSpriteFrame. Invalid frame");
//	
//	self.spriteFrame = frame.spriteFrame;
//}

#pragma mark CCSprite - Effects

- (void)updateShaderUniformsFromEffect
{
    // Initialize the shader uniforms dictionary with the sprite's main texture and
    // normal map if it has them.
    [_shaderUniforms release];
    _shaderUniforms = [@{ CCShaderUniformMainTexture : (_texture ?: [CCTexture none]),
                          CCShaderUniformNormalMapTexture : (_normalMapSpriteFrame.texture ?: [CCTexture none]),
                          } mutableCopy];
    
    // And then copy the new effect's uniforms into the node's uniforms dictionary.
    [_shaderUniforms addEntriesFromDictionary:_effect.effectImpl.shaderUniforms];
}

@end

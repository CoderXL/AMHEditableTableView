//
//  EditableTableController.m
//  XYEdit
//
//  Created by Alfred Hanssen on 8/15/14.
//  Copyright (c) 2014 XY. All rights reserved.
//

#import "EditableTableController.h"

static CGFloat MinLongPressDuration = 0.30f;
static CGFloat ZoomAnimationDuration = 0.20f;

@interface EditableTableController ()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIView *snapshotView;

@property (nonatomic, strong) NSIndexPath *initialIndexPath;
@property (nonatomic, strong) NSIndexPath *previousIndexPath;

@end

@implementation EditableTableController

- (instancetype)init
{
    NSAssert(NO, @"Use custom initializer");
    return nil;
}

- (instancetype)initWithTableView:(UITableView *)tableView
{
    NSAssert(tableView != nil, @"tableView cannot be nil.");
    NSAssert([tableView numberOfSections] == 1, @"This class currently supports single section tableViews only.");
    NSAssert(tableView.estimatedRowHeight > 0, @"The tableView's estimatedRowHeight must be set.");

    self = [super init];
    if (self)
    {
        _enabled = YES;
        _tableView = tableView;
        
        [self setupGestureRecognizer];
    }
    
    return self;
}

- (void)cancel
{
    self.longPressRecognizer.enabled = NO;
    self.longPressRecognizer.enabled = YES;
}

#pragma mark - Setup

- (void)setupGestureRecognizer
{
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeLongPress:)];
    self.longPressRecognizer.minimumPressDuration = MinLongPressDuration;
    [_tableView addGestureRecognizer:self.longPressRecognizer];
}

#pragma mark - Accessors

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled)
    {
        _enabled = enabled;
        
        self.longPressRecognizer.enabled = enabled;
    }
}

#pragma mark - Gestures

- (void)didRecognizeLongPress:(UILongPressGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:recognizer.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (indexPath == nil)
        {
            [self cancel];
            return;
        }

        self.initialIndexPath = indexPath;
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
        self.snapshotView = [cell snapshotViewAfterScreenUpdates:NO];
        self.snapshotView.frame = CGRectOffset(self.snapshotView.bounds, rect.origin.x, rect.origin.y);        
        [self.tableView addSubview:self.snapshotView];
        
        // Trigger animation...
        [UIView animateWithDuration:ZoomAnimationDuration animations:^{
            self.snapshotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.snapshotView.center = CGPointMake(self.tableView.center.x, location.y);
        }];
    
        // ...before modifying tableView
        if (self.delegate && [self.delegate respondsToSelector:@selector(editableTableController:willBeginMovingCellAtIndexPath:)])
        {
            [self.delegate editableTableController:self willBeginMovingCellAtIndexPath:indexPath];
        }
        
        self.previousIndexPath = indexPath;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        self.snapshotView.center = (CGPoint){self.tableView.center.x, location.y};

        // Only notify delegate upon moving above a new cell
        if (self.previousIndexPath && indexPath && ![self.previousIndexPath isEqual:indexPath])
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(editableTableController:movedCellWithInitialIndexPath:fromAboveIndexPath:toAboveIndexPath:)])
            {
                [self.delegate editableTableController:self movedCellWithInitialIndexPath:self.initialIndexPath fromAboveIndexPath:self.previousIndexPath toAboveIndexPath:indexPath];
            }
        }
        
        self.previousIndexPath = indexPath;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.snapshotView.center = (CGPoint){self.tableView.center.x, location.y};

        // Check if the cell being moved is above the first cell or below the last
        if (indexPath == nil)
        {
            CGFloat cellHeight = [self.tableView estimatedRowHeight];
            NSInteger count = [self.tableView numberOfRowsInSection:0];
            if (location.y > count * cellHeight)
            {
                indexPath = [NSIndexPath indexPathForRow:count - 1 inSection:0];
            }
            else if (location.y <= 0)
            {
                indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            }
        }
        
        CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];

        [UIView animateWithDuration:ZoomAnimationDuration animations:^{
            self.snapshotView.transform = CGAffineTransformIdentity;
            self.snapshotView.center = (CGPoint){CGRectGetMidX(rect), CGRectGetMidY(rect)};
        } completion:^(BOOL finished) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(editableTableController:didMoveCellFromInitialIndexPath:toIndexPath:)])
            {
                [self.delegate editableTableController:self didMoveCellFromInitialIndexPath:self.initialIndexPath toIndexPath:indexPath];
            }

            [self.snapshotView removeFromSuperview];
            self.snapshotView = nil;
            
            self.initialIndexPath = nil;
            self.previousIndexPath = nil;
        }];
    }
}

@end

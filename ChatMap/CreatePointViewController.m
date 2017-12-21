//
//  CreatePointViewController.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 25.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "CreatePointViewController.h"
#import "AppCore.h"


@interface CreatePointViewController () <UITextViewDelegate>


@property (weak) IBOutlet UILabel *captionLabel;
@property (weak) IBOutlet UILabel *placeholderLabel;
@property (weak) IBOutlet UITextView *textView;

@property (weak) IBOutlet UIButton *cancelButton;
@property (weak) IBOutlet UIButton *sendButton;

@end

@implementation CreatePointViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    // Do any additional setup after loading the view.
    _captionLabel.text = TRANSLATE(@"Create marker");
    _placeholderLabel.text = TRANSLATE(@"Type description...");
    _textView.text = @"";
    _textView.delegate = self;
    _textView.textColor = [UIColor lightGrayColor];
    _textView.layer.cornerRadius = 10.0;
    _textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _textView.layer.borderWidth = 1.0;
    _textView.layer.masksToBounds = YES;
    
    BUTTON_TITLE(_sendButton, TRANSLATE(@"Done"));
    BUTTON_TITLE(_cancelButton, TRANSLATE(@"Cancel"));
    
    _cancelButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _cancelButton.layer.borderWidth = 1.0;
    _cancelButton.layer.cornerRadius = 10;
    _cancelButton.clipsToBounds = true;
    
    _sendButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _sendButton.layer.borderWidth = 1.0;
    _sendButton.layer.cornerRadius = 10;
    _sendButton.clipsToBounds = true;
    
    [_textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (!_placeholderLabel.alpha && !textView.text.length) {
        [UIView animateWithDuration:0.3 animations:^{
            _placeholderLabel.alpha = 1.0;
        }];
        return;
    }
    if (_placeholderLabel.alpha && textView.text.length) {
        [UIView animateWithDuration:0.3 animations:^{
            _placeholderLabel.alpha = 0.0;
        }];
        return;
    }
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [APP onCreatePoint:NO];
    }];
}

-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [APP createPoint:_textView.text];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end

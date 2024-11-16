import {
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { NgForm } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { BlogCommentCreate } from '../../../models/blog-comment/blog-comment-create.model';
import { BlogCommentViewModel } from '../../../models/blog-comment/blog-comment-view-model.model';
import { BlogComment } from '../../../models/blog-comment/blog-comment.model';
import { BlogCommentService } from '../../../services/blog-comment.service';

@Component({
  selector: 'app-comment-box',
  templateUrl: './comment-box.component.html',
  styleUrls: ['./comment-box.component.css'],
})
export class CommentBoxComponent implements OnInit {
  @Input() comment: BlogCommentViewModel = new BlogCommentViewModel();
  @Output() commentSaved = new EventEmitter<BlogComment>();

  @ViewChild('commentForm') commentForm: NgForm = new NgForm([], []);

  constructor(
    private blogCommentService: BlogCommentService,
    private toastr: ToastrService
  ) {}

  ngOnInit(): void {}

  resetComment() {
    this.commentForm.reset();
  }

  onSubmit() {
    let blogCommentCreate: BlogCommentCreate = {
      blogCommentId: this.comment.blogCommentId,
      parentBlogCommentId: this.comment.parentBlogCommentId,
      blogId: this.comment.blogId,
      content: this.comment.content,
    };

    this.blogCommentService
      .create(blogCommentCreate)
      .subscribe((blogComment) => {
        this.toastr.info('Comment saved.');
        this.resetComment();
        this.commentSaved.emit(blogComment);
      });
  }
}

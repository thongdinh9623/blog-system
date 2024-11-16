import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Blog } from '../../../models/blog/blog.model';
import { BlogService } from '../../../services/blog.service';
import { PhotoService } from '../../../services/photo.service';

@Component({
  selector: 'app-blog',
  templateUrl: './blog.component.html',
  styleUrls: ['./blog.component.css'],
})
export class BlogComponent implements OnInit {
  blog: Blog = new Blog();
  blogPhotoUrl: string = '';

  constructor(
    private route: ActivatedRoute,
    private blogService: BlogService,
    private photoService: PhotoService
  ) {}

  ngOnInit(): void {
    const blogId = parseInt(this.route.snapshot.paramMap.get('id') ?? '');

    this.blogService.get(blogId).subscribe((blog) => {
      this.blog = blog;

      if (!!this.blog.photoId) {
        this.photoService.get(this.blog.photoId).subscribe((photo) => {
          this.blogPhotoUrl = photo.imageUrl;
        });
      }
    });
  }
}

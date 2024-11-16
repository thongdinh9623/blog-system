export class BlogCommentViewModel {
  constructor(
    public parentBlogCommentId: number = 0,
    public blogCommentId: number = 0,
    public blogId: number = 0,
    public content: string = '',
    public username: string = '',
    public publishDate: Date = new Date(),
    public updateDate: Date = new Date(),
    public isEditable: boolean = false,
    public deleteConfirm: boolean = false,
    public isReplying: boolean = false,
    public comments: BlogCommentViewModel[] = []
  ) {}
}

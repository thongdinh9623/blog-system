export class Blog {
  constructor(
    public blogId: number = 0,
    public title: string = '',
    public content: string = '',
    public applicationUserId: number = 0,
    public username: string = '',
    public publishDate: Date = new Date(),
    public updateDate: Date = new Date(),
    public deleteConfirm: boolean = false,
    public photoId?: number
  ) {}
}

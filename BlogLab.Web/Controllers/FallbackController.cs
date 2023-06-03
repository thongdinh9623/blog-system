using Microsoft.AspNetCore.Mvc;
using System.IO;

namespace BlogLab.Web.Controllers
{
    [ApiController]
    public class FallbackController : Controller
    {
        public ActionResult Index()
        {
            return PhysicalFile(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "index.html"), "text/HTML");
        }
    }
}

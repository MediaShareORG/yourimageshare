using YourImageShare;

var client = new YourImageShareClient("YOUR_API_KEY");

try
{
    var result = await client.UploadAsync("photo.jpg");
    Console.WriteLine(result.Direct);
}
catch (YourImageShareException ex)
{
    Console.Error.WriteLine($"{ex.Status}: {ex.ApiMessage}");
    Environment.Exit(1);
}

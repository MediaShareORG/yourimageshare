use yourimageshare::{ApiError, Client};

fn main() {
    let client = Client::new("YOUR_API_KEY");

    match client.upload("photo.jpg", None) {
        Ok(result) => println!("{}", result.direct),
        Err(ApiError { status, message }) => {
            eprintln!("{status}: {message}");
            std::process::exit(1);
        }
    }
}

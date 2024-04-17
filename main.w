bring cloud;
bring dynamodb;
bring expect;
bring http;
bring util;

let api = new cloud.Api() as "books_manager"; 

let table = new dynamodb.Table(
  name: "books",
  attributes: [
    {
      name: "ID",
      type: "S"
    }
  ],
  hashKey: "ID"
);

api.get("/books/:bookID", inflight (req) => {
  let bookID = req.vars.get("bookID");
  log("Getting record with ID {bookID}");

  let result = table.get(
    Key: {
      ID: bookID
    }
  );
  
  let book = result.Item;
  if (book == nil) {
    return {
     status: 404,
     body: "Book not found"
    };
  }

  let response = {
    id: book?.get("ID"),
    title: book?.get("Title"),
    author: book?.get("Author"),
    createdAt: book?.get("CreatedAt")
  };

  return {
   status: 200,
   body: Json.stringify(response)
  };
});

struct BookRequest { 
  title: str;
  author: str; 
} 

struct BookResponse extends BookRequest { 
  id: str; 
  createdAt: str; 
}

api.post("/books", inflight (req) => {
  let bookRequest = BookRequest.tryParseJson(req.body);
  if (bookRequest == nil) {
    return {
      status: 400,
      body: "Request invalid"
    };
  }

  if (bookRequest?.title == nil || bookRequest?.author == nil) {
    return {
      status: 400,
      body: "Title and author are required"
    };
  }

  let bookID = util.uuidv4();
  let createdAt = std.Datetime.utcNow();

  table.put(
    Item: {
      ID: bookID,
      Title: bookRequest?.title,
      Author: bookRequest?.author,
      CreatedAt: createdAt.toIso()
    }
  );

  let response = BookResponse {
    id: bookID,
    title: bookRequest?.title!,
    author: bookRequest?.author!,
    createdAt: createdAt.toIso()
  };

  return {
   status: 200,
   body: Json.stringify(response)
  };
});

/*
***********
Tests
***********
*/
test "GET /books/:bookID should return 200 when record exists" {
  let id = "1";
  let author = "An Author";
  let title = "A Book";
  let createdAt = "2024-04-14";

  table.put(
    Item: {
      ID: id,
      Title: title,
      Author: author,
      CreatedAt: createdAt
    }
  );

  let result = http.get("{api.url}/books/{id}");
  let body = BookResponse.parseJson(result.body);

  expect.equal(result.status, 200);
  expect.equal(body.id, id);
  expect.equal(body.author, author);
  expect.equal(body.title, title);
  expect.equal(body.createdAt, createdAt);
}

test "GET /books/:bookID should return 404 when record is not found" {
  let id = "1";
  let result = http.get("{api.url}/books/{id}");
  expect.equal(result.status, 404);
}

test "POST /books should return 200 with correct body " {
  let request = BookRequest {title: "A Title", author: "An Author"};

  let body = Json.stringify(request);

  let result = http.post("{api.url}/books", { body: body });
  let responseBody = BookResponse.parseJson(result.body);

  expect.equal(result.status, 200);
  expect.equal(responseBody.author, request.author);
  expect.equal(responseBody.title, request.title);
  expect.notNil(responseBody.id);
  expect.notNil(responseBody.createdAt);
}

test "POST /books should return 400 without body " {
  let result = http.post("{api.url}/books");
  expect.equal(result.status, 400);
}

test "POST /books should return 400 with empty body " {
  let body = Json.stringify({});
  let result = http.post("{api.url}/books", { body: body });
  expect.equal(result.status, 400);
}

test "POST /books should return 400 without title " {
  let body = Json.stringify({ author: "An Author"});
  let result = http.post("{api.url}/books", { body: body });
  expect.equal(result.status, 400);
}

test "POST /books should return 400 without author " {
  let body = Json.stringify({title: "A Title" });
  let result = http.post("{api.url}/books", { body: body });
  expect.equal(result.status, 400);
}
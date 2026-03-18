using Microsoft.Extensions.Logging;
using Xunit;
using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Moq;
using System.IO;

namespace tests
{
    public class TestCounter
    {
        [Fact]
        public void Http_trigger_should_return_known_string()
        {
            // Arrange
            var counter = new Company.Function.Counter
            {
                Id = "1",
                Count = 2
            };

            var loggerFactory = new Mock<ILoggerFactory>();
            var logger = new Mock<ILogger<Company.Function.GetResumeCounter>>();
            loggerFactory.Setup(x => x.CreateLogger(It.IsAny<string>())).Returns(logger.Object);

            var context = new Mock<FunctionContext>();
            var request = new Mock<HttpRequestData>(context.Object);

            var response = new Mock<HttpResponseData>(context.Object);
            response.SetupProperty(r => r.Headers, new HttpHeadersCollection());
            response.SetupProperty(r => r.StatusCode, HttpStatusCode.OK);
            response.SetupProperty(r => r.Body, new MemoryStream());

            request.Setup(r => r.CreateResponse(It.IsAny<HttpStatusCode>())).Returns(response.Object);

            var function = new Company.Function.GetResumeCounter(loggerFactory.Object);

            // Act
            var result = function.Run(request.Object, counter);

            // Assert
            Assert.Equal(3, result.Document.Count);
            Assert.Equal(HttpStatusCode.OK, result.HttpResponse.StatusCode);
        }

    }
}
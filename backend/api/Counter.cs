using Newtonsoft.Json;

namespace Company.Function
{
    public class Counter
    {
        [JsonProperty(PropertyName = "id")]
        public required string Id {get; set;}
        [JsonProperty(PropertyName = "count")]
        public int Count {get; set;}
    }
}
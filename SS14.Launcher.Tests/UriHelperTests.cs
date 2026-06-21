using System;
using NUnit.Framework;

namespace SS14.Launcher.Tests;

[TestFixture]
[Parallelizable(ParallelScope.All)]
public class UriHelperTests
{
    [Test]
    [TestCase("server.ss14.art", "http://server.ss14.art:1212/status")]
    [TestCase("ss14s://server.ss14.art", "https://server.ss14.art/status")]
    [TestCase("ss14s://server.ss14.art:1212", "https://server.ss14.art:1212/status")]
    [TestCase("ss14s://server.ss14.art/foo", "https://server.ss14.art/foo/status")]
    public void GetServerStatusAddress(string input, string expected)
    {
        var uri = UriHelper.GetServerStatusAddress(input);

        Assert.That(uri, Is.EqualTo(new Uri(expected)));
    }
}
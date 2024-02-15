from mamba import description, it, context, fit, fcontext
from expects import expect, be_true, be_false

with description("This is a test description"):
    with context("first context"):
        with it("first test"):
            expect(True).to(be_true)

    with fcontext("second fixed context"):
        with it("second test"):
            expect(True).to(be_true)

    with it("test outside context"):
        expect(True).to(be_false)

    with fit("fixed test outside context"):
        expect(True).to(be_false)
